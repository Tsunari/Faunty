import 'package:flutter/material.dart';
import 'dart:math' as math;
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

  const AttendanceTable({
    super.key,
    required this.users,
    required this.attendanceItems,
    required this.attendance,
    required this.placeId,
    required this.useTabs,
    required this.selectedItem,
    required this.onSelectedItemChanged,
  });

  @override
  State<AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<AttendanceTable> {
  late final ScrollController _timeScrollCtrl;
  late final ScrollController _namesScrollCtrl;
  late final ScrollController _gridScrollCtrl;
  bool _isSyncingV = false;
  late DateTime _startDay;
  late DateTime _today;
  late String _todayKey;
  String _visibleMonth = '';
  String _selectedItem = '';
  int _numDays = 30; // initial window size
  Map<String, dynamic> _attendanceCache = {};
  bool _isExtending = false;
  static const int _pageDays = 30;
  static const double _colWidthConst = 36.0;
  final Map<String, bool> _expanded = {};

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
    _visibleMonth = _monthNameFromDate(_startDay);
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
    super.dispose();
  }

  void _onHorizontalScroll() {
    if (!_timeScrollCtrl.hasClients || _isExtending) return;
    final pos = _timeScrollCtrl.position;
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
        _startDay = _startDay.subtract(const Duration(days: _pageDays));
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
    final firstDate = _startDay.add(Duration(days: firstIndex));
    final next = _monthNameFromDate(firstDate);
    if (next != _visibleMonth) setState(() => _visibleMonth = next);
  }

  Future<void> _scrollToToday() async {
    if (_today.isBefore(_startDay)) {
      final diff = _startDay.difference(_today).inDays;
      setState(() {
        _startDay = _today.subtract(Duration(days: 5));
        _numDays = (_numDays + diff + 10).clamp(_numDays, 3650);
      });
    } else if (_today.isAfter(_startDay.add(Duration(days: _numDays - 1)))) {
      final diff = _today.difference(_startDay.add(Duration(days: _numDays - 1))).inDays;
      setState(() {
        _numDays = _numDays + diff + 10;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timeScrollCtrl.hasClients) return;
      final targetIndex = _today.difference(_startDay).inDays;
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
    final itemsMeta = widget.attendanceItems;
    final attendance = _attendanceCache;

  // Prefer roster provided by attendance stream (AttendanceFirestoreService adds it),
  // otherwise fall back to the full users list.
  final List<String> roster = (attendance['roster'] as List?)?.cast<String>() ?? users.map((u) => u.uid).toList();
    // helper to get display name for uid
    String displayNameFor(String uid) {
      final u = users.firstWhere(
        (e) => e.uid == uid,
        orElse: () => UserEntity(uid: uid, email: '', firstName: '', lastName: '', role: UserRole.user, placeId: ''),
      );
      final full = '${u.firstName} ${u.lastName}'.trim();
      return full.isEmpty ? uid : full;
    }
    final List<String> columns = List.generate(
      _numDays,
      (i) => _fmt(_startDay.add(Duration(days: i))),
    );

    final double nameColWidth = 170;
    final double rowHeight = 28;
    final double baseDayColWidth = _colWidthConst;
    final double headingHeight = 72;
    final double availableWidth = MediaQuery.of(context).size.width - nameColWidth - 24;
    final double dayColWidth = baseDayColWidth;
    final double totalWidth = (columns.length * dayColWidth) > availableWidth ? columns.length * dayColWidth : availableWidth;
    final monthLabel = _visibleMonth.isEmpty ? _monthNameFromDate(_startDay) : _visibleMonth;

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
                            child: Text(
                              monthLabel,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(onPressed: _scrollToToday, icon: const Icon(Icons.today), color: theme.colorScheme.primary, tooltip: 'Today'),
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
                          final expanded = _expanded[userId] ?? false;
                          final itemCount = itemsMeta.isEmpty ? 1 : itemsMeta.length;
                          final blockHeight = expanded ? rowHeight * (1 + itemCount) : rowHeight;
                          return InkWell(
                            onTap: () => setState(() => _expanded[userId] = !(expanded)),
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
                                final expanded = _expanded[userId] ?? false;
                                final renderedItems = <Map<String, dynamic>>[];
                                final defaultIdOrName = _selectedItem.isNotEmpty ? _selectedItem : (itemsMeta.isNotEmpty ? (itemsMeta.first['id'] as String) : 'presence');
                                final defaultItem = itemsMeta.firstWhere((e) => (e['id'] == defaultIdOrName) || (e['name'] == defaultIdOrName), orElse: () => itemsMeta.isNotEmpty ? itemsMeta.first : {'id': 'presence', 'name': 'Presence'});
                                renderedItems.add(defaultItem);
                                if (expanded) renderedItems.addAll(itemsMeta);
                                return Column(
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
                                            for (final d in columns)
                                              Container(
                                                width: dayColWidth,
                                                decoration: BoxDecoration(
                                                  color: d == _todayKey ? theme.colorScheme.primary.withOpacity(0.06) : null,
                                                  border: Border(
                                                    right: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Transform.scale(
                                                    scale: 0.9,
                                                    child: _InlineCell(
                                                      placeId: widget.placeId,
                                                      dateKey: d,
                                                      userId: userId,
                                                      attendance: attendance,
                                                      itemName: it['id'] as String,
                                                      onToggleLocal: (dateK, itemId, uid, isChecked) {
                                                        setState(() {
                                                          final next = Map<String, dynamic>.from(_attendanceCache);
                                                          final dateRec = Map<String, dynamic>.from(next[dateK] as Map? ?? {});
                                                          final rec = Map<String, dynamic>.from(dateRec[itemId] as Map? ?? {});
                                                          final present = List<String>.from((rec['present'] as List?)?.cast<String>() ?? <String>[]);
                                                          final absent = List<String>.from((rec['absent'] as List?)?.cast<String>() ?? <String>[]);
                                                          if (isChecked) {
                                                            if (!present.contains(uid)) present.add(uid);
                                                            absent.remove(uid);
                                                          } else {
                                                            present.remove(uid);
                                                            if (!absent.contains(uid)) absent.add(uid);
                                                          }
                                                          rec['present'] = present;
                                                          rec['absent'] = absent;
                                                          dateRec[itemId] = rec;
                                                          next[dateK] = dateRec;
                                                          _attendanceCache = next;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
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

  String _monthNameFromDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[dt.month - 1];
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
  final void Function(String dateKey, String itemId, String userId, bool checked)? onToggleLocal;
  const _InlineCell({Key? key, required this.placeId, required this.dateKey, required this.userId, required this.attendance, required this.itemName, this.onToggleLocal}) : super(key: key);

  @override
  State<_InlineCell> createState() => _InlineCellState();
}

class _InlineCellState extends State<_InlineCell> {
  late bool checked;

  @override
  void initState() {
    super.initState();
    final dateRec = Map<String, dynamic>.from(widget.attendance[widget.dateKey] as Map? ?? {});
    final rec = Map<String, dynamic>.from(dateRec[widget.itemName] as Map? ?? {});
    final present = (rec['present'] as List?)?.cast<String>() ?? const <String>[];
    checked = present.contains(widget.userId);
  }

  @override
  void didUpdateWidget(covariant _InlineCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dateRec = Map<String, dynamic>.from(widget.attendance[widget.dateKey] as Map? ?? {});
    final rec = Map<String, dynamic>.from(dateRec[widget.itemName] as Map? ?? {});
    final present = (rec['present'] as List?)?.cast<String>() ?? const <String>[];
    final newChecked = present.contains(widget.userId);
    if (newChecked != checked) setState(() => checked = newChecked);
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: checked,
      onChanged: (val) async {
        setState(() => checked = val ?? false);
        widget.onToggleLocal?.call(widget.dateKey, widget.itemName, widget.userId, checked);
        await AttendanceFirestoreService(widget.placeId).toggleAttendanceItem(dateId: widget.dateKey, itemId: widget.itemName, userId: widget.userId, checked: checked);
      },
    );
  }
}
