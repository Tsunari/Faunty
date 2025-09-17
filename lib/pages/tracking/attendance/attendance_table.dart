import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../firestore/attendance_firestore_service.dart';
import 'package:faunty/models/user_entity.dart';
import 'package:faunty/models/user_roles.dart';

class AttendanceTable extends StatefulWidget {
  final List<UserEntity> users;
  final List<Map<String, dynamic>> attendanceItems;
  final Map<String, dynamic> attendance;
  final String placeId;
  final bool useTabs;
  final String selectedItem;
  final ValueChanged<String> onSelectedItemChanged;
  final UserEntity currentUser;

  const AttendanceTable({
    super.key,
    required this.users,
    required this.attendanceItems,
    required this.attendance,
    required this.placeId,
    required this.useTabs,
    required this.selectedItem,
    required this.onSelectedItemChanged,
    required this.currentUser,
  });

  @override
  State<AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<AttendanceTable> with TickerProviderStateMixin {
  late final ScrollController _timeScrollCtrl;
  late final ScrollController _namesScrollCtrl;
  late final ScrollController _gridScrollCtrl;
  bool _isSyncingV = false;
  late DateTime _startDay;
  late DateTime _today;
  late String _todayKey;
  String _visibleMonth = '';
  late final ValueNotifier<String> _visibleMonthVN = ValueNotifier<String>('');
  late final ValueNotifier<Set<String>> _expandedVN = ValueNotifier<Set<String>>(<String>{});
  String _selectedItem = '';
  int _numDays = 30; // initial window size
  Map<String, dynamic> _attendanceCache = {};
  // cache for quick uid -> display name lookup to avoid repeated firstWhere calls
  late final Map<String, String> _displayNameMap = {};
  // last seen uid->role mapping to detect in-place role changes
  final Map<String, UserRole> _lastKnownRoles = {};
  // cache generated columns for current _startDay/_numDays window
  List<String>? _columnsCache;
  int? _columnsCacheNumDays;
  int? _columnsCacheStartEpoch;
  // pending optimistic changes keyed by "date|item|user" -> 'present' | 'absent' | 'onLeave'
  late final ValueNotifier<Map<String, String>> _pendingVN; // value: tri-state
  late final _AttendanceBatcher _batcher;
  bool _isExtending = false;
  static const int _pageDays = 30;
  static const double _colWidthConst = 36.0;
  // last first-visible column index observed (used for simple virtualization)
  int _lastFirstVisibleCol = 0;

  @override
  void initState() {
    super.initState();
    _timeScrollCtrl = ScrollController();
    _namesScrollCtrl = ScrollController();
    _gridScrollCtrl = ScrollController();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _todayKey = _fmt(_today);
    _startDay = _today;
    _visibleMonth = _monthAndYearFromDate(_startDay);
    _visibleMonthVN.value = _visibleMonth;
    _timeScrollCtrl.addListener(_onHorizontalScroll);
    _namesScrollCtrl.addListener(() {
      if (_isSyncingV) return;
      _isSyncingV = true;
      if (_gridScrollCtrl.hasClients) {
        _gridScrollCtrl.jumpTo(
          _namesScrollCtrl.position.pixels.clamp(
            0.0,
            _gridScrollCtrl.position.maxScrollExtent,
          ),
        );
      }
      _isSyncingV = false;
    });
    _gridScrollCtrl.addListener(() {
      if (_isSyncingV) return;
      _isSyncingV = true;
      if (_namesScrollCtrl.hasClients) {
        _namesScrollCtrl.jumpTo(
          _gridScrollCtrl.position.pixels.clamp(
            0.0,
            _namesScrollCtrl.position.maxScrollExtent,
          ),
        );
      }
      _isSyncingV = false;
    });
    _attendanceCache = Map<String, dynamic>.from(widget.attendance);
    _selectedItem = widget.selectedItem;
    // keep pending markers until server confirms the change
    _batcher = _AttendanceBatcher(widget.placeId);
  _pendingVN = ValueNotifier<Map<String, String>>({});
  // build initial display name cache and record roles
  _updateUsersCache();
    if (_selectedItem.isEmpty) {
      SharedPreferences.getInstance().then((sp) {
        final key = 'attendance_default_${widget.placeId}';
        final saved = sp.getString(key);
        if (saved != null && saved.isNotEmpty) {
          setState(() => _selectedItem = saved);
        } else if (widget.attendanceItems.isNotEmpty) {
          setState(() => _selectedItem = widget.attendanceItems.first['id'] as String? ?? '');
        }
      });
    }
  }

  @override
  void dispose() {
    _timeScrollCtrl.removeListener(_onHorizontalScroll);
    _timeScrollCtrl.dispose();
    _namesScrollCtrl.dispose();
    _gridScrollCtrl.dispose();
    _visibleMonthVN.dispose();
    _expandedVN.dispose();
    _batcher.dispose();
    _pendingVN.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AttendanceTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    var needRebuild = false;
    if (oldWidget.attendance != widget.attendance) {
      _attendanceCache = Map<String, dynamic>.from(widget.attendance);
      needRebuild = true;
    }

    // If the attendance map instance didn't change, it might still have been mutated
    // (for example the 'roster' nested list). Detect roster changes and merge them into
    // our cache so UI stays up-to-date while still benefiting from caching.
    final incomingRoster = (widget.attendance['roster'] as List?)?.cast<String>();
    final cachedRoster = (_attendanceCache['roster'] as List?)?.cast<String>();
    if (!_listEquals(incomingRoster ?? <String>[], cachedRoster ?? <String>[]) ) {
      // merge roster into cache
      if (incomingRoster == null) {
        _attendanceCache.remove('roster');
      } else {
        _attendanceCache['roster'] = List<String>.from(incomingRoster);
      }
      needRebuild = true;
    }

    // If users list changed (by uid) we should update UI and clean up state such as expanded rows.
    final oldUids = oldWidget.users.map((u) => u.uid).toList();
    final newUids = widget.users.map((u) => u.uid).toList();
    // Rebuild if uid list changed
    if (!_listEquals(oldUids, newUids)) {
      final existing = newUids.toSet();
      final nextExpanded = _expandedVN.value.where((e) => existing.contains(e)).toSet();
      _expandedVN.value = nextExpanded;
      needRebuild = true;
      _updateUsersCache();
    } else {
      // Uid list is same, but roles or other user properties might have changed.
      // Detect role changes by comparing uid->role signature.
      final oldRoles = {for (var u in oldWidget.users) u.uid: u.role};
      final newRoles = {for (var u in widget.users) u.uid: u.role};
      if (!_mapEquals(oldRoles, newRoles)) {
        needRebuild = true;
        _updateUsersCache();
      }
    }

    if (needRebuild) setState(() {});
  }

  void _updateUsersCache() {
    _displayNameMap.clear();
    _lastKnownRoles.clear();
    for (final u in widget.users) {
      final full = '${u.firstName} ${u.lastName}'.trim();
      _displayNameMap[u.uid] = full.isEmpty ? u.uid : full;
      _lastKnownRoles[u.uid] = u.role;
    }
  }

  List<String> _buildColumns() {
    final startEpoch = _startDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    if (_columnsCache != null && _columnsCacheNumDays == _numDays && _columnsCacheStartEpoch == startEpoch) {
      return _columnsCache!;
    }
    final cols = List.generate(
      _numDays,
      (i) => _fmt(_startDay.subtract(Duration(days: i))),
    );
    _columnsCache = cols;
    _columnsCacheNumDays = _numDays;
    _columnsCacheStartEpoch = startEpoch;
    return cols;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  void _onHorizontalScroll() {
    if (!_timeScrollCtrl.hasClients || _isExtending) return;
    final pos = _timeScrollCtrl.position;
    final firstIndexNow = (pos.pixels / _colWidthConst).floor().clamp(0, _numDays - 1);
    if (firstIndexNow != _lastFirstVisibleCol) {
      _lastFirstVisibleCol = firstIndexNow;
      // trigger rebuild so we only create visible columns (CRAZY PERFORMANCE WIN)
      setState(() {});
    }
    const double threshold = _colWidthConst * 8;
    if (pos.maxScrollExtent - pos.pixels < threshold) {
      setState(() {
        _isExtending = true;
        _numDays += _pageDays;
      });
      _isExtending = false;
      _updateVisibleMonth();
      return;
    }
    if (pos.pixels < threshold) {
      setState(() {
        _isExtending = true;
        _startDay = _startDay.add(const Duration(days: _pageDays));
        _numDays += _pageDays;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_timeScrollCtrl.hasClients) {
          _timeScrollCtrl.jumpTo(_timeScrollCtrl.offset + _pageDays * _colWidthConst);
        }
        _isExtending = false;
        _updateVisibleMonth();
      });
      return;
    }
    _updateVisibleMonth();
  }

  void _updateVisibleMonth() {
    if (!_timeScrollCtrl.hasClients) return;
    final offset = _timeScrollCtrl.offset;
    final firstIndex = (offset / _colWidthConst).floor().clamp(0, _numDays - 1);
    final firstDate = _startDay.subtract(Duration(days: firstIndex));
    final next = _monthAndYearFromDate(firstDate);
    if (next != _visibleMonth) {
      _visibleMonth = next;
      _visibleMonthVN.value = next;
    }
  }

  Future<void> _scrollToToday() async {
    // In reversed order, columns cover [_startDay - (_numDays - 1), _startDay]
    final endDate = _startDay.subtract(Duration(days: _numDays - 1));
    if (_today.isAfter(_startDay)) {
      final diff = _today.difference(_startDay).inDays;
      setState(() {
        _startDay = _today.add(const Duration(days: 5));
        _numDays = (_numDays + diff + 10).clamp(_numDays, 3650);
      });
    } else if (_today.isBefore(endDate)) {
      final diff = endDate.difference(_today).inDays;
      setState(() {
        _numDays = _numDays + diff + 10;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timeScrollCtrl.hasClients) return;
      final targetIndex = _startDay.difference(_today).inDays;
      final targetOffset = (targetIndex * _colWidthConst).toDouble();
      _timeScrollCtrl.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      _updateVisibleMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = widget.users;
    // Keep display name and role caches up-to-date even if the provider mutated
    // the users list in-place. This is intentionally done without calling
    // setState to avoid losing rebuild optimizations; updating the cache is
    // cheap and only affects local lookup maps used during rendering.
    var usersCacheMismatch = false;
    if (_lastKnownRoles.length != users.length) {
      usersCacheMismatch = true;
    } else {
      for (final u in users) {
        final last = _lastKnownRoles[u.uid];
        if (last != u.role) {
          usersCacheMismatch = true;
          break;
        }
      }
    }
    if (usersCacheMismatch) {
      _updateUsersCache();
    }
    final itemsMeta = widget.attendanceItems;
    final attendance = _attendanceCache;

    // Prefer roster provided by attendance stream (AttendanceFirestoreService adds it),
    // otherwise derive roster from users but only include roles that should appear in attendance.
    final providedRoster = (attendance['roster'] as List?)?.cast<String>();
    // If attendance provides a roster, treat it as authoritative but still filter
    // against current users and their roles - this ensures role changes hide users
    // even if the roster was cached and not updated.
    final List<String> roster = (providedRoster != null)
        ? providedRoster.where((uid) {
            final u = users.cast<UserEntity?>().firstWhere((e) => e?.uid == uid, orElse: () => null);
            if (u == null) return false;
            return u.role == UserRole.talebe || u.role == UserRole.baskan;
          }).toList()
        : users.where((u) {
            // Only show talebe and baskan in roster by default; adjust roles here as needed.
            return u.role == UserRole.talebe || u.role == UserRole.baskan;
          }).map((u) => u.uid).toList();
  // helper to get display name for uid using cached map
  String displayNameFor(String uid) => _displayNameMap[uid] ?? uid;
  final List<String> columns = _buildColumns();
  // virtualization window: build only visible columns plus a small buffer
  final visibleWidth = MediaQuery.of(context).size.width - 170 - 24; // availableWidth used later
  final visibleColsCount = (visibleWidth / _colWidthConst).ceil() + 4; // buffer
  final firstVisible = _lastFirstVisibleCol.clamp(0, columns.length - 1);
  final startCol = firstVisible;
  final endCol = (firstVisible + visibleColsCount).clamp(0, columns.length);
  final leftSpacerWidth = startCol * _colWidthConst;
  final rightSpacerWidth = math.max(0.0, (columns.length - endCol) * _colWidthConst);

    final double nameColWidth = 170;
    final double rowHeight = 28;
    final double baseDayColWidth = _colWidthConst;
    final double headingHeight = 72;
    final double availableWidth = MediaQuery.of(context).size.width - nameColWidth - 24;
    final double dayColWidth = baseDayColWidth;
    final double totalWidth = (columns.length * dayColWidth) > availableWidth ? columns.length * dayColWidth : availableWidth;

    return Column(
      children: [
        if (widget.useTabs)
          DefaultTabController(
            length: itemsMeta.length,
            initialIndex: math.max(0, itemsMeta.indexWhere((e) => (e['id'] == _selectedItem) || (e['name'] == _selectedItem))),
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: [for (final it in itemsMeta) Tab(text: it['name'] as String? ?? '')],
                  onTap: (idx) async {
                    final sel = itemsMeta[idx]['id'] as String? ?? itemsMeta[idx]['name'] as String? ?? '';
                    setState(() => _selectedItem = sel);
                    widget.onSelectedItemChanged(sel);
                    final sp = await SharedPreferences.getInstance();
                    await sp.setString('attendance_default_${widget.placeId}', sel);
                    final metaMap = await AttendanceFirestoreService(widget.placeId).getAttendanceMeta();
                    if (metaMap.containsKey('default')) {
                      metaMap.remove('default');
                      await AttendanceFirestoreService(widget.placeId).setAttendanceMeta(metaMap);
                    }
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: nameColWidth,
                child: Column(
                  children: [
                    Container(
                      height: headingHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
                      child: Row(
                        children: [
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: _visibleMonthVN,
                              builder: (context, label, _) {
                                return Text(
                                  label.isEmpty ? _monthAndYearFromDate(_startDay) : label,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _scrollToToday,
                            icon: const Icon(Icons.today),
                            color: theme.colorScheme.primary,
                            tooltip: 'Today',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: _namesScrollCtrl,
                        itemCount: roster.isEmpty ? 1 : roster.length,
                        itemBuilder: (context, idx) {
                          if (roster.isEmpty) {
                            return Container(
                              height: rowHeight,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('No users in roster', style: theme.textTheme.bodyMedium),
                            );
                          }
                          final userId = roster[idx];
                          return ValueListenableBuilder<Set<String>>(
                            valueListenable: _expandedVN,
                            builder: (context, expandedSet, _) {
                              final expanded = expandedSet.contains(userId);
                              final itemCount = itemsMeta.isEmpty ? 1 : itemsMeta.length;
                              final blockHeight = expanded ? rowHeight * (1 + itemCount) : rowHeight;
                              return InkWell(
                                onTap: () {
                                  final next = Set<String>.from(expandedSet);
                                  if (expanded) {
                                    next.remove(userId);
                                  } else {
                                    next.add(userId);
                                  }
                                  _expandedVN.value = next;
                                },
                                child: Container(
                                    height: blockHeight,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)))),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: SizedBox(
                                          height: rowHeight,
                                          child: Row(children: [Expanded(child: Text(displayNameFor(userId), overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)), Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18)]),
                                        ),
                                      ),
                                      if (expanded)
                                        for (var i = 0; i < itemCount; i++)
                                          Flexible(
                                            fit: FlexFit.loose,
                                            child: SizedBox(
                                              height: rowHeight,
                                              child: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 8.0), child: Text(i < itemsMeta.length ? (itemsMeta[i]['name'] as String? ?? '') : '', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false)),
                                            ),
                                          ),
                                    ]),
                                  ),
                                );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  final gridHeight = math.max(0.0, constraints.maxHeight - 1);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _timeScrollCtrl,
                    child: SizedBox(
                      width: totalWidth,
                      child: Column(
                        children: [
                          Container(
                            height: headingHeight,
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
                            child: Row(
                              children: [
                                for (final d in columns)
                                  Container(
                                    width: dayColWidth,
                                    decoration: BoxDecoration(
                                      color: d == _todayKey ? theme.colorScheme.primary.withOpacity(0.08) : null,
                                      border: Border(
                                        right: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                      ),
                                    ),
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text(_verticalLabel(d), style: theme.textTheme.labelSmall),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: math.max(0.0, gridHeight - headingHeight),
                            child: ListView.builder(
                              controller: _gridScrollCtrl,
                              itemCount: roster.isEmpty ? 1 : roster.length,
                              itemBuilder: (context, rIdx) {
                                if (roster.isEmpty) {
                                  return Container(
                                    height: rowHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        for (final _ in columns)
                                          Container(
                                            width: dayColWidth,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }
                                final userId = roster[rIdx];
                                return ValueListenableBuilder<Set<String>>(
                                  valueListenable: _expandedVN,
                                  builder: (context, expandedSet, _) {
                                    final expanded = expandedSet.contains(userId);
                                    final renderedItems = <Map<String, dynamic>>[];
                                    final defaultIdOrName = _selectedItem.isNotEmpty ? _selectedItem : (itemsMeta.isNotEmpty ? (itemsMeta.first['id'] as String) : 'presence');
                                    final defaultItem = itemsMeta.firstWhere((e) => (e['id'] == defaultIdOrName) || (e['name'] == defaultIdOrName), orElse: () => itemsMeta.isNotEmpty ? itemsMeta.first : {'id': 'presence', 'name': 'Presence'});
                                    renderedItems.add(defaultItem);
                                    if (expanded) renderedItems.addAll(itemsMeta);
                                    return RepaintBoundary(
                                      child: Column(
                                          children: [
                                            for (final it in renderedItems)
                                              Container(
                                                height: rowHeight,
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // left spacer to keep scroll position consistent
                                                    SizedBox(width: leftSpacerWidth),
                                                    for (int ci = startCol; ci < endCol; ci++)
                                                      Container(
                                                        width: dayColWidth,
                                                        decoration: BoxDecoration(
                                                          color: columns[ci] == _todayKey ? theme.colorScheme.primary.withOpacity(0.06) : null,
                                                          border: Border(
                                                            right: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Transform.scale(
                                                            scale: 0.9,
                                                            child: RepaintBoundary(
                                                              child: _InlineCell(
                                                                placeId: widget.placeId,
                                                                dateKey: columns[ci],
                                                                userId: userId,
                                                                attendance: attendance,
                                                                itemName: it['id'] as String,
                                                                currentUser: widget.currentUser,
                                                                pendingLookup: (key) => _pendingVN.value[key],
                                                                onToggle: (key, state) {
                                                                  // optimistic update: replace map to notify listeners
                                                                  final next = Map<String, String>.from(_pendingVN.value);
                                                                  next[key] = state;
                                                                  _pendingVN.value = next;
                                                                  _batcher.enqueueState(key, state);
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    // right spacer to preserve total width
                                                    SizedBox(width: rightSpacerWidth),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _verticalLabel(String key) {
    final dt = _parseKey(key);
    final weekday = _weekdayAbbr(dt.weekday);
    return '${two(dt.day)} $weekday';
  }

  String _monthAndYearFromDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final yy = dt.year % 100;
    final yyStr = yy < 10 ? '0$yy' : '$yy';
    return "${months[dt.month - 1]} $yyStr";
  }

  DateTime _parseKey(String key) {
    try {
      final parts = key.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return DateTime.now();
    }
  }

  String two(int v) => v < 10 ? '0$v' : '$v';

  String _weekdayAbbr(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}

class _InlineCell extends StatefulWidget {
  final String placeId;
  final String dateKey;
  final String userId;
  final Map<String, dynamic> attendance;
  final String itemName;
  final UserEntity currentUser;
  final String? Function(String key)? pendingLookup; // returns 'present' | 'absent' | 'onLeave'
  final void Function(String key, String state)? onToggle; // state: 'present' | 'absent' | 'onLeave'

  const _InlineCell({required this.placeId, required this.dateKey, required this.userId, required this.attendance, required this.itemName, required this.currentUser, this.pendingLookup, this.onToggle});

  @override
  State<_InlineCell> createState() => _InlineCellState();
}

class _InlineCellState extends State<_InlineCell> {
  late final ValueNotifier<String> _stateVN; // 'present' | 'absent' | 'onLeave'

  @override
  void initState() {
    super.initState();
    _stateVN = ValueNotifier<String>(_lookupState());
  }

  @override
  void didUpdateWidget(covariant _InlineCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = _lookupState();
    if (newVal != _stateVN.value) _stateVN.value = newVal;
  }

  String _lookupState() {
    final key = '${widget.dateKey}|${widget.itemName}|${widget.userId}';
    final pending = widget.pendingLookup?.call(key);
    if (pending != null) return pending;
    final dateRec = widget.attendance[widget.dateKey] as Map<String, dynamic>?;
    final rec = dateRec == null ? null : (dateRec[widget.itemName] as Map<String, dynamic>?);
    final present = rec == null ? const <String>[] : (rec['present'] as List?)?.cast<String>() ?? const <String>[];
    final onLeave = rec == null ? const <String>[] : (rec['onLeave'] as List?)?.cast<String>() ?? const <String>[];
    final absent = rec == null ? const <String>[] : (rec['absent'] as List?)?.cast<String>() ?? const <String>[];
    if (present.contains(widget.userId)) return 'present';
    if (onLeave.contains(widget.userId)) return 'onLeave';
    if (absent.contains(widget.userId)) return 'absent';
    return 'absent';
  }

  @override
  void dispose() {
    _stateVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.currentUser.role.index <= UserRole.baskan.index;
    final key = '${widget.dateKey}|${widget.itemName}|${widget.userId}';
    return ValueListenableBuilder<String>(
      valueListenable: _stateVN,
      builder: (context, state, _) {
        Widget icon;
        Color? bg;
        Color? border;
        final scheme = Theme.of(context).colorScheme;
        if (state == 'present') {
          icon = Icon(Icons.check, size: 16, color: scheme.onPrimary);
          bg = scheme.primary;
          border = scheme.primary;
        } else if (state == 'onLeave') {
          icon = Icon(Icons.info_outline, size: 16, color: scheme.primary);
          bg = scheme.primary.withOpacity(0.08);
          border = scheme.primary;
        } else {
          icon = const SizedBox.shrink();
          bg = null;
          border = Theme.of(context).dividerColor.withOpacity(0.6);
        }

        void handleTap() {
          if (!canEdit) return;
          String next;
          if (state == 'absent') {
            next = 'present';
          } else if (state == 'present') {
            next = 'onLeave';
          } else {
            next = 'absent';
          }
          _stateVN.value = next;
          widget.onToggle?.call(key, next);
        }

        return Semantics(
          button: true,
          label: 'Attendance state: $state',
          child: InkWell(
            onTap: canEdit ? handleTap : null,
            borderRadius: BorderRadius.circular(3),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        );
      },
    );
  }
}

/// Helper that batches attendance toggles and flushes them to Firestore.
class _AttendanceBatcher {
  final String placeId;
  // no callback: pending markers are reconciled from incoming attendance data
  final Map<String, String> _buffer = {}; // value: 'present' | 'absent' | 'onLeave'
  final Duration _debounce = const Duration(milliseconds: 250);
  Timer? _timer;
  bool _disposed = false;

  _AttendanceBatcher(this.placeId);

  void enqueueState(String key, String state) {
    if (_disposed) return;
    _buffer[key] = state;
    _timer?.cancel();
    _timer = Timer(_debounce, _flush);
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty || _disposed) return;
    final toSend = Map<String, String>.from(_buffer);
    _buffer.clear();
    // Transform into date/item -> list of users present operations
    // We'll call AttendanceFirestoreService.setAttendanceItemState for each entry.
    final service = AttendanceFirestoreService(placeId);
    // Fire off writes in parallel but wait for them to finish.
    final futures = <Future<void>>[];
    toSend.forEach((compositeKey, state) {
      final parts = compositeKey.split('|');
      if (parts.length != 3) return;
      final dateId = parts[0];
      final itemId = parts[1];
      final userId = parts[2];
      futures.add(service.setAttendanceItemState(dateId: dateId, itemId: itemId, userId: userId, state: state));
    });
    try {
      await Future.wait(futures);
  // nothing to do here - parent reconciles pending keys against incoming attendance
    } catch (_) {
      // re-add failed items so another attempt can pick them up
      _buffer.addAll(toSend);
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _buffer.clear();
  }
}
