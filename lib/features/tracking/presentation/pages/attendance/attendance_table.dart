import 'package:flutter/material.dart';
import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faunty/features/tracking/data/repositories/attendance_firestore_service.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_chip.dart';

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
  // passive users map (uid -> true)
  final Map<String, bool> _passiveUsers = {};
  bool _isExtending = false;
  static const int _pageDays = 30;
  static const double _colWidthConst = 36.0;
  // last first-visible column index observed (used for simple virtualization)
  int _lastFirstVisibleCol = 0;
  TabController? _tabCtrl;
  int _selectedIndex = 0;

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
    // load passive users from meta
    AttendanceFirestoreService(widget.placeId).getAttendanceMeta().then((meta) {
      final p = (meta['passiveUsers'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      setState(() {
        _passiveUsers
          ..clear()
          ..addEntries(
            p.entries
                .where((e) => e.value == true)
                .map((e) => MapEntry(e.key, true)),
          );
      });
    }).catchError((_) {});
    // Initialize TabController if tabs used
    if (widget.useTabs && widget.attendanceItems.isNotEmpty) {
      final idx = math.max(0, widget.attendanceItems.indexWhere((e) => (e['id'] == _selectedItem) || (e['name'] == _selectedItem)));
      _selectedIndex = idx < 0 ? 0 : idx;
      _tabCtrl = TabController(length: widget.attendanceItems.length, vsync: this, initialIndex: _selectedIndex);
    }
    if (_selectedItem.isEmpty) {
      SharedPreferences.getInstance().then((sp) {
        final key = 'attendance_default_${widget.placeId}';
        final saved = sp.getString(key);
        if (saved != null && saved.isNotEmpty) {
          setState(() {
            _selectedItem = saved;
            if (widget.useTabs && widget.attendanceItems.isNotEmpty) {
              final idx = widget.attendanceItems.indexWhere((e) => (e['id'] == _selectedItem) || (e['name'] == _selectedItem));
              _selectedIndex = idx >= 0 ? idx : 0;
              if (_tabCtrl != null && _selectedIndex < _tabCtrl!.length) {
                _tabCtrl!.index = _selectedIndex;
              }
            }
          });
        } else if (widget.attendanceItems.isNotEmpty) {
          setState(() {
            _selectedItem = widget.attendanceItems.first['id'] as String? ?? '';
            _selectedIndex = 0;
            if (_tabCtrl != null) _tabCtrl!.index = 0;
          });
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
    _tabCtrl?.dispose();
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

    // Rebuild TabController when items list changes
    if (widget.useTabs) {
      final oldLen = oldWidget.attendanceItems.length;
      final newLen = widget.attendanceItems.length;
      final selectionIdx = math.max(0, widget.attendanceItems.indexWhere((e) => (e['id'] == _selectedItem) || (e['name'] == _selectedItem)));
      final nextIndex = selectionIdx >= 0 ? selectionIdx : 0;
      if (_tabCtrl == null || oldLen != newLen) {
        _tabCtrl?.dispose();
        _tabCtrl = TabController(length: newLen, vsync: this, initialIndex: nextIndex.clamp(0, math.max(newLen - 1, 0)));
        _selectedIndex = _tabCtrl!.index;
      } else if (_tabCtrl != null && _tabCtrl!.length == newLen && _tabCtrl!.index != nextIndex) {
        _tabCtrl!.index = nextIndex;
        _selectedIndex = nextIndex;
      }
    }
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

  // Return weekdays allowed for the currently selected item (1..7)
  List<int> _currentItemWeekdays() {
    final itemsMeta = widget.attendanceItems;
    if (itemsMeta.isEmpty) return const [1, 2, 3, 4, 5, 6, 7];
    final selectedMeta = itemsMeta.firstWhere(
      (e) => e['id'] == _selectedItem || e['name'] == _selectedItem,
      orElse: () => itemsMeta.first,
    );
    final List<int> wd = ((selectedMeta['weekdays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7])
        .where((d) => d >= 1 && d <= 7)
        .toList();
    if (wd.isEmpty) return const [1, 2, 3, 4, 5, 6, 7];
    return wd;
  }

  // Filter date keys by weekdays
  List<String> _filterColumnsByWeekdays(List<String> keys, List<int> weekdays) {
    if (weekdays.length == 7) return keys;
    final set = weekdays.toSet();
    return keys.where((k) => set.contains(_parseKey(k).weekday)).toList();
  }

  List<int> _weekdaysFromItemMeta(Map<String, dynamic> it) {
    return ((it['weekdays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7])
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  int _nearestIndexForDate(List<String> cols, DateTime target) {
    if (cols.isEmpty) return 0;
    final key = _fmt(target);
    int idx = cols.indexOf(key);
    if (idx >= 0) return idx;
    // try forward up to 7 days
    for (int i = 1; i <= 7; i++) {
      final fwdKey = _fmt(target.add(Duration(days: i)));
      idx = cols.indexOf(fwdKey);
      if (idx >= 0) return idx;
    }
    // try backward up to 7 days
    for (int i = 1; i <= 7; i++) {
      final backKey = _fmt(target.subtract(Duration(days: i)));
      idx = cols.indexOf(backKey);
      if (idx >= 0) return idx;
    }
    // fallback: clamp to closest boundary by date compare
    // cols are descending by date: index 0 is most recent
    // find first col whose date <= target
    final firstLE = cols.indexWhere((e) => !_parseKey(e).isAfter(target));
    if (firstLE >= 0) return firstLE;
    return cols.length - 1;
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
      final prevStart = _startDay;
      // Count how many of the newly prepended days match the current selected weekdays
      final Set<int> weekdays = _currentItemWeekdays().toSet();
      int addedFiltered = 0;
      for (int d = 1; d <= _pageDays; d++) {
        final dt = prevStart.add(Duration(days: d));
        if (weekdays.contains(dt.weekday)) addedFiltered++;
      }
      setState(() {
        _isExtending = true;
        _startDay = _startDay.add(const Duration(days: _pageDays));
        _numDays += _pageDays;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_timeScrollCtrl.hasClients) {
          final delta = (addedFiltered * _colWidthConst);
          final nextOffset = _timeScrollCtrl.offset + delta;
          _timeScrollCtrl.jumpTo(nextOffset);
          final allCols = _buildColumns();
          final cols = _filterColumnsByWeekdays(allCols, _currentItemWeekdays());
          if (cols.isNotEmpty) {
            final idx = (nextOffset / _colWidthConst).floor().clamp(0, cols.length - 1);
            setState(() {
              _lastFirstVisibleCol = idx;
            });
          }
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
    final int firstIndex = (offset / _colWidthConst).floor();
    final List<String> allCols = _buildColumns();
    final cols = _filterColumnsByWeekdays(allCols, _currentItemWeekdays());
    if (cols.isEmpty) return;
    final safeIndex = firstIndex.clamp(0, cols.length - 1);
    final key = cols[safeIndex];
    final firstDate = _parseKey(key);
    final next = _monthAndYearFromDate(firstDate);
    if (next != _visibleMonth) {
      _visibleMonth = next;
      _visibleMonthVN.value = next;
    }
  }

  Future<void> _scrollToToday() async {
    final List<int> wk = _currentItemWeekdays();
    if (wk.isEmpty) return;
    // Find nearest allowed date (today if allowed, else next within 6 days, else previous within 6 days)
    DateTime target = _today;
    if (!wk.contains(target.weekday)) {
      bool found = false;
      for (int i = 1; i <= 6; i++) {
        final fwd = _today.add(Duration(days: i));
        if (wk.contains(fwd.weekday)) {
          target = fwd;
          found = true;
          break;
        }
      }
      if (!found) {
        for (int i = 1; i <= 6; i++) {
          final back = _today.subtract(Duration(days: i));
          if (wk.contains(back.weekday)) {
            target = back;
            break;
          }
        }
      }
    }
    // Ensure target is inside the current window, else extend
    final windowStart = _startDay;
    final windowEnd = _startDay.subtract(Duration(days: _numDays - 1));
    if (target.isAfter(windowStart)) {
      setState(() {
        _startDay = target.add(const Duration(days: 5));
        // extend if needed
        _numDays = (_numDays + target.difference(windowStart).inDays + 10).clamp(_numDays, 3650);
      });
    } else if (target.isBefore(windowEnd)) {
      setState(() {
        _numDays = _numDays + windowEnd.difference(target).inDays + 10;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timeScrollCtrl.hasClients) return;
      final cols = _filterColumnsByWeekdays(_buildColumns(), wk);
      if (cols.isEmpty) return;
      final key = _fmt(target);
      int idx = cols.indexOf(key);
      if (idx < 0) {
        // if not found (edge of window), clamp to nearest
        // Find first col >= target
        idx = cols.indexWhere((e) => !_parseKey(e).isAfter(target));
        if (idx < 0) idx = (cols.length - 1).clamp(0, cols.length - 1);
      }
      final targetOffset = (idx * _colWidthConst).toDouble();
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
  final List<String> allColumns = _buildColumns();
  // Determine selected item meta
  // latenessEnabled handled per-cell via item meta flag
  final List<int> selectedWeekdays = _currentItemWeekdays();
  // Filter columns by weekdays for the selected item
  final List<String> columns = _filterColumnsByWeekdays(allColumns, selectedWeekdays);
  // virtualization window: build only visible columns plus a small buffer
  final visibleWidth = MediaQuery.of(context).size.width - 170 - 24; // availableWidth used later
  final visibleColsCount = (visibleWidth / _colWidthConst).ceil() + 4; // buffer
  // Compute first visible index from the current horizontal scroll offset for robustness
  final firstVisible = (columns.isEmpty || !_timeScrollCtrl.hasClients)
      ? 0
      : (_timeScrollCtrl.offset / _colWidthConst).floor().clamp(0, columns.length - 1);
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
        if (widget.useTabs && itemsMeta.isNotEmpty)
          Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [for (final it in itemsMeta) Tab(text: it['name'] as String? ?? '')],
                onTap: (idx) async {
                  final sel = itemsMeta[idx]['id'] as String? ?? itemsMeta[idx]['name'] as String? ?? '';
                  // Anchor: compute current visible date from current filter and offset
                  DateTime? anchorDate;
                  if (_timeScrollCtrl.hasClients) {
                    final allCols = _buildColumns();
                    final currentCols = _filterColumnsByWeekdays(allCols, _currentItemWeekdays());
                    if (currentCols.isNotEmpty) {
                      final curIdx = (_timeScrollCtrl.offset / _colWidthConst).floor().clamp(0, currentCols.length - 1);
                      anchorDate = _parseKey(currentCols[curIdx]);
                    }
                  }
                  setState(() {
                    _selectedItem = sel;
                    _selectedIndex = idx;
                  });
                  widget.onSelectedItemChanged(sel);
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString('attendance_default_${widget.placeId}', sel);
                  final metaMap = await AttendanceFirestoreService(widget.placeId).getAttendanceMeta();
                  if (metaMap.containsKey('default')) {
                    metaMap.remove('default');
                    await AttendanceFirestoreService(widget.placeId).setAttendanceMeta(metaMap);
                  }
                  // After selection, align scroll based on new filter using a post-frame clamp
                  if (anchorDate != null) {
                    final DateTime anchor = anchorDate;
                    final int tappedIdx = idx;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_timeScrollCtrl.hasClients) return;
                      final allCols2 = _buildColumns();
                      final newWeekdays = _weekdaysFromItemMeta(itemsMeta[tappedIdx]);
                      final newCols = _filterColumnsByWeekdays(allCols2, newWeekdays);
                      if (newCols.isEmpty) return;
                      final newIdx = _nearestIndexForDate(newCols, anchor);
                      final unclamped = (newIdx * _colWidthConst).toDouble();
                      final max = _timeScrollCtrl.position.maxScrollExtent;
                      final target = unclamped.clamp(0.0, max);
                      setState(() {
                        _lastFirstVisibleCol = newIdx.clamp(0, newCols.length - 1);
                      });
                      _timeScrollCtrl.jumpTo(target);
                      _updateVisibleMonth();
                    });
                  }
                },
              ),
              const Divider(height: 1),
            ],
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
                                          child: Row(children: [
                                            Expanded(child: Text(displayNameFor(userId), overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
                                            // passive hint when collapsed
                                            if (!expanded && (_passiveUsers[userId] == true))
                                              Padding(
                                                padding: const EdgeInsets.only(right: 6.0),
                                                child: Icon(
                                                  Icons.pause_circle_outline,
                                                  size: 14,
                                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                                ),
                                              ),
                                            // Passive toggle shown in expanded row
                                            if (expanded)
                                              Row(children: [
                                                RoleGate(
                                                  minRole: UserRole.baskan,
                                                  child: IconButton(
                                                  iconSize: 18,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints.tightFor(width: 20, height: 20),
                                                  visualDensity: VisualDensity.compact,
                                                  splashRadius: 14,
                                                  tooltip: 'Passive',
                                                  onPressed: () async {
                                                    final next = !(_passiveUsers[userId] ?? false);
                                                    // persist without snackbar
                                                    await AttendanceFirestoreService(widget.placeId).setUserPassive(userId, next);
                                                    setState(() {
                                                      if (next) {
                                                        _passiveUsers[userId] = true;
                                                      } else {
                                                        _passiveUsers.remove(userId);
                                                      }
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _passiveUsers[userId] == true ? Icons.pause_circle_filled : Icons.pause_circle_outline,
                                                    size: 18,
                                                  ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                              ]),
                                            Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18)
                                          ]),
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
                                                                latenessEnabled: ((it['latenessEnabled'] as bool?) ?? false),
                                                                pendingLookup: (key) => _pendingVN.value[key],
                                                                onToggle: (key, state) async {
                                                                  // optimistic update: replace map to notify listeners
                                                                  final next = Map<String, String>.from(_pendingVN.value);
                                                                  next[key] = state;
                                                                  _pendingVN.value = next;
                                                                  _batcher.enqueueState(key, state);
                                                                  // If this is today's date, perform passive auto-fill for other passive users
                                                                  if (columns[ci] == _todayKey) {
                                                                    // compute last-known state for each passive user and enqueue writes
                                                                    final passiveUids = _passiveUsers.keys.toList();
                                                                    bool anyPassiveUpdated = false;
                                                                    for (final pu in passiveUids) {
                                                                      if (pu == userId) continue; // skip the user who triggered the change
                                                                      final passiveKey = '${columns[ci]}|${it['id']}|$pu';
                                                                      // If passive user's today cell already has a state, skip
                                                                      final dateRec = attendance[columns[ci]] as Map<String, dynamic>?;
                                                                      final rec = dateRec == null ? null : (dateRec[it['id']] as Map<String, dynamic>?);
                                                                      final present = rec == null ? const <String>[] : (rec['present'] as List?)?.cast<String>() ?? const <String>[];
                                                                      final onLeave = rec == null ? const <String>[] : (rec['onLeave'] as List?)?.cast<String>() ?? const <String>[];
                                                                      final absent = rec == null ? const <String>[] : (rec['absent'] as List?)?.cast<String>() ?? const <String>[];
                                                                      final alreadyExplicit = present.contains(pu) || onLeave.contains(pu) || absent.contains(pu);
                                                                      // Attempt when today's state is not explicitly set (implicit or explicit default)
                                                                      if (alreadyExplicit) continue;
                                                                      // find last known state by scanning columns (descending)
                                                                      final allCols = _buildColumns();
                                                                      final filteredCols = _filterColumnsByWeekdays(allCols, _currentItemWeekdays());
                                                                      String? lastState;
                                                                      for (final ck in filteredCols) {
                                                                        if (ck == columns[ci]) continue; // skip today
                                                                        final drec = attendance[ck] as Map<String, dynamic>?;
                                                                        final r = drec == null ? null : (drec[it['id']] as Map<String, dynamic>?);
                                                                        if (r == null) continue;
                                                                        final p = (r['present'] as List?)?.cast<String>() ?? const <String>[];
                                                                        final l = (r['onLeave'] as List?)?.cast<String>() ?? const <String>[];
                                                                        final a = (r['absent'] as List?)?.cast<String>() ?? const <String>[];
                                                                         // no default check here; default is intentionally ignored
                                                                        if (p.contains(pu)) {
                                                                          lastState = 'present';
                                                                          break;
                                                                        }
                                                                        if (l.contains(pu)) {
                                                                          lastState = 'onLeave';
                                                                          break;
                                                                        }
                                                                        if (a.contains(pu)) {
                                                                          lastState = 'absent';
                                                                          break;
                                                                        }
                                                                      }
                                                                      // If no explicit state found, do nothing (no default fallback)
                                                                      if (lastState != null) {
                                                                        // optimistic pending for passive cell
                                                                        final nextPending = Map<String, String>.from(_pendingVN.value);
                                                                        nextPending[passiveKey] = lastState;
                                                                        _pendingVN.value = nextPending;
                                                                        _batcher.enqueueState(passiveKey, lastState);
                                                                        anyPassiveUpdated = true;
                                                                      }
                                                                    }
                                                                    if (anyPassiveUpdated) {
                                                                      setState(() {});
                                                                    }
                                                                  }
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
  final bool latenessEnabled;

  const _InlineCell({required this.placeId, required this.dateKey, required this.userId, required this.attendance, required this.itemName, required this.currentUser, this.pendingLookup, this.onToggle, this.latenessEnabled = false});

  @override
  State<_InlineCell> createState() => _InlineCellState();
}

class _InlineCellState extends State<_InlineCell> {
  late final ValueNotifier<String> _stateVN; // 'present' | 'absent' | 'onLeave' | 'default'
  late final ValueNotifier<int?> _lateVN; // minutes

  @override
  void initState() {
    super.initState();
    _stateVN = ValueNotifier<String>(_lookupState());
    _lateVN = ValueNotifier<int?>(_lookupLateMinutes());
  }

  @override
  void didUpdateWidget(covariant _InlineCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = _lookupState();
    if (newVal != _stateVN.value) _stateVN.value = newVal;
    final newLate = _lookupLateMinutes();
    if (newLate != _lateVN.value) _lateVN.value = newLate;
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
    final def = rec == null ? const <String>[] : (rec['default'] as List?)?.cast<String>() ?? const <String>[];
    if (present.contains(widget.userId)) return 'present';
    if (onLeave.contains(widget.userId)) return 'onLeave';
    if (absent.contains(widget.userId)) return 'absent';
    if (def.contains(widget.userId)) return 'default';
    return 'default';
  }

  @override
  void dispose() {
    _stateVN.dispose();
    _lateVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.currentUser.role.index <= UserRole.baskan.index;
    final key = '${widget.dateKey}|${widget.itemName}|${widget.userId}';
    return ValueListenableBuilder<String>(
      valueListenable: _stateVN,
      builder: (context, state, _) {
        final scheme = Theme.of(context).colorScheme;
        Widget icon;
        Color? bg;
        Color? border;
        if (state == 'present') {
          icon = Icon(Icons.check, size: 16, color: scheme.onPrimary);
          bg = scheme.primary;
          border = scheme.primary;
        } else if (state == 'absent') {
          icon = Icon(Icons.remove, size: 16, color: scheme.error);
          bg = scheme.error.withOpacity(0.08);
          border = scheme.error;
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
          if (state == 'present') {
            next = 'absent';
          } else if (state == 'absent') {
            next = 'onLeave';
          } else if (state == 'onLeave') {
            next = 'default';
          } else {
            next = 'present';
          }
          _stateVN.value = next;
          widget.onToggle?.call(key, next);
        }

        Widget base = Semantics(
          button: true,
          label: 'Attendance state: $state',
          child: InkWell(
            onTap: canEdit ? handleTap : null,
            onLongPress: widget.latenessEnabled && canEdit ? () => _editLateMinutes(context) : null,
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                if (widget.latenessEnabled)
                  Positioned(
                    right: -5,
                    top: -1,
                    child: ValueListenableBuilder<int?>(
                      valueListenable: _lateVN,
                      builder: (context, minutes, __) {
                        final has = minutes != null && minutes > 0;
                        if (!has) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${minutes}m',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: Theme.of(context).colorScheme.onTertiary,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );

        return base;
      },
    );
  }

  int? _lookupLateMinutes() {
    final dateRec = widget.attendance[widget.dateKey] as Map<String, dynamic>?;
    final rec = dateRec == null ? null : (dateRec[widget.itemName] as Map<String, dynamic>?);
    final lateMap = rec == null ? null : (rec['lateMinutes'] as Map<String, dynamic>?);
    final val = lateMap == null ? null : lateMap[widget.userId];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return null;
  }

  Future<void> _editLateMinutes(BuildContext context) async {
    final controller = TextEditingController(text: (_lateVN.value ?? 0).toString());
    final minutes = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        void adjust(int delta) {
          final current = int.tryParse(controller.text.trim()) ?? 0;
          final next = (current + delta).clamp(0, 600);
          controller.text = next.toString();
        }
        return AlertDialog(
          title: Text(translation(context: context, 'Set lateness (minutes)')),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // decrement chips
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(onTap: () => adjust(-5), child: const CustomChip(label: '-5', fontSize: 11)),
                  const SizedBox(height: 6),
                  InkWell(onTap: () => adjust(-15), child: const CustomChip(label: '-15', fontSize: 11)),
                  const SizedBox(height: 6),
                  InkWell(onTap: () => adjust(-30), child: const CustomChip(label: '-30', fontSize: 11)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: translation(context: context, 'e.g. 10'),
                      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      suffixIcon: IconButton(
                        tooltip: translation(context: context, 'Remove'),
                        icon: const Icon(Icons.delete_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => Navigator.pop(ctx, -1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // increment chips
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(onTap: () => adjust(5), child: const CustomChip(label: '+5', fontSize: 11)),
                  const SizedBox(height: 6),
                  InkWell(onTap: () => adjust(15), child: const CustomChip(label: '+15', fontSize: 11)),
                  const SizedBox(height: 6),
                  InkWell(onTap: () => adjust(30), child: const CustomChip(label: '+30', fontSize: 11)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(translation(context: context, 'Cancel'))),
            ElevatedButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                Navigator.pop(ctx, v);
              },
              child: Text(translation(context: context, 'Save')),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (minutes == null) return; // Cancel only
    final clamped = minutes <= 0 ? null : minutes.clamp(1, 600); // allow up to 10h theoretical
    await AttendanceFirestoreService(widget.placeId).setLateMinutes(
      dateId: widget.dateKey,
      itemId: widget.itemName,
      userId: widget.userId,
      minutes: clamped is int ? clamped : null,
    );
    _lateVN.value = clamped is int ? clamped : null;
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