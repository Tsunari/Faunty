import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/features/lists/presentation/controllers/program_provider.dart';

class ProgramOrganisationCalendarV2 extends ConsumerStatefulWidget {
  const ProgramOrganisationCalendarV2({super.key});

  @override
  ConsumerState<ProgramOrganisationCalendarV2> createState() => _ProgramOrganisationCalendarV2State();
}

class _ProgramOrganisationCalendarV2State extends ConsumerState<ProgramOrganisationCalendarV2> {
  DateTime _selectedDay = DateTime.now();
  final int _startHour = 5;
  final int _endHour = 23;
  int _slotMinutes = 15;
  final double _slotHeight = 36.0; // height per 15-min slot
  final List<int> _slotOptions = [5, 10, 15];

  final ScrollController _scroll = ScrollController();
  final List<_Block> _blocks = [];
  _Block? _tempBlock;
  _Block? _editing;
  final TextEditingController _editController = TextEditingController();
  Map<String, List<Map<String, String>>>? _latestWeekProgram;
  DateTime? _loadedDay;
  final Map<String, List<_Block>> _localDrafts = {};
  final Set<String> _dirtyDays = {};
  // Moving state for drag-to-move existing blocks
  _Block? _movingBlock;
  Duration? _movingBlockDuration;
  double _movingAccumulatedDy = 0.0;
  // Additional state for long-press move handling
  DateTime? _movingOriginalStart;
  double? _movingStartLocalDy;
  int? _movingLastAppliedSlotShift;

  DateTime _slotToTime(int slotIndex) {
    final minutes = slotIndex * _slotMinutes;
    final hour = _startHour + minutes ~/ 60;
    final minute = minutes % 60;
    return DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
  }

  int _dyToSlot(double dy) => (dy / _slotHeight).floor().clamp(0, ((_endHour - _startHour) * (60 ~/ _slotMinutes)) - 1);

  double _slotToDY(int slot) => slot * _slotHeight;

  void _startAt(Offset localPos) {
    // If the long-press started on an existing block, don't create a new temp block.
    final hit = _blockAtLocalPosition(localPos);
    if (hit != null) return;

    final dy = localPos.dy + _scroll.offset;
    final slot = _dyToSlot(dy);
    final start = _slotToTime(slot);
    setState(() {
      _tempBlock = _Block(name: '', start: start, end: start.add(Duration(minutes: _slotMinutes)));
    });
  }

  void _updateAt(Offset localPos) {
    if (_tempBlock == null) return;
    final dy = localPos.dy + _scroll.offset;
    final slot = _dyToSlot(dy);
    final currentPos = _slotToTime(slot);
    // Determine start and end based on drag direction
    // Start is always the earlier time, end is always the later time
    final start = _tempBlock!.start.isBefore(currentPos) ? _tempBlock!.start : currentPos;
    final end = _tempBlock!.start.isBefore(currentPos) ? currentPos : _tempBlock!.start;
    setState(() {
      _tempBlock = _tempBlock!.copyWith(start: start, end: end.add(Duration(minutes: _slotMinutes)));
    });
  }

  // Return the block at a given local position (or null). Uses the same
  // scroll offset and slot computation as the drag-to-create logic so the
  // detection is consistent with where a temp block would be created.
  _Block? _blockAtLocalPosition(Offset localPos) {
    if (_blocks.isEmpty) return null;
    final dy = localPos.dy + _scroll.offset;
    final slot = _dyToSlot(dy);
    final time = _slotToTime(slot);
    for (final b in _blocks) {
      if (!time.isBefore(b.start) && time.isBefore(b.end)) return b;
    }
    return null;
  }

  void _endAt() {
    if (_tempBlock == null) return;
    setState(() {
      _blocks.add(_tempBlock!);
      _editing = _tempBlock;
      _editController.text = '';
      _tempBlock = null;
      // mark draft dirty for current day
      _localDrafts[_dayKeyForSelected()] = _blocks.map((b) => b.copyWith()).toList();
      _dirtyDays.add(_dayKeyForSelected());
    });
  }

  // Long-press move handlers extracted to separate methods for clarity.
  void _onBlockLongPressStart(_Block block, LongPressStartDetails details) {
    if (_editing != null) return;
    setState(() {
      _movingBlock = block;
      _movingBlockDuration = block.end.difference(block.start);
      _movingAccumulatedDy = 0.0;
      _movingOriginalStart = block.start;
      _movingStartLocalDy = details.localPosition.dy + _scroll.offset;
      _movingLastAppliedSlotShift = 0;
    });
  }

  void _onBlockLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_movingBlock == null || _movingBlockDuration == null || _movingOriginalStart == null || _movingStartLocalDy == null) return;
    final currentDy = details.localPosition.dy + _scroll.offset;
    final dy = currentDy - _movingStartLocalDy!;
    // Determine rounded slot shift and only apply when it changes from last-applied.
    final slotShift = (dy / _slotHeight).round();
    if (_movingLastAppliedSlotShift == null || slotShift != _movingLastAppliedSlotShift) {
      final minutesShift = slotShift * _slotMinutes;
      final newStart = _movingOriginalStart!.add(Duration(minutes: minutesShift));
      final earliest = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, _startHour, 0);
      final latestStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, _endHour, 0).subtract(_movingBlockDuration!);
      final clamped = newStart.isBefore(earliest) ? earliest : (newStart.isAfter(latestStart) ? latestStart : newStart);
      // Only update if start actually differs to avoid unnecessary rebuilds
      if (!_movingBlock!.start.isAtSameMomentAs(clamped)) {
        setState(() {
          _movingBlock!.start = clamped;
          _movingBlock!.end = clamped.add(_movingBlockDuration!);
          _localDrafts[_dayKeyForSelected()] = _blocks.map((bb) => bb.copyWith()).toList();
          _dirtyDays.add(_dayKeyForSelected());
        });
      }
      _movingLastAppliedSlotShift = slotShift;
    }
  }

  void _onBlockLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _movingBlock = null;
      _movingBlockDuration = null;
      _movingAccumulatedDy = 0.0;
      _movingOriginalStart = null;
      _movingStartLocalDy = null;
      _movingLastAppliedSlotShift = null;
    });
  }

  String _dayKeyForSelected() {
    // Use full weekday name keys as in Firestore/service
    return DateFormat.EEEE().format(_selectedDay);
  }

  List<Map<String, String>> _serializeBlocksForDay() {
    return _blocks.map((b) => {
      'from': DateFormat('HH:mm').format(b.start),
      'to': DateFormat('HH:mm').format(b.end),
      'event': b.name,
    }).toList();
  }

  List<_Block> _deserializeBlocksForEntries(List<Map<String, String>> entries) {
    return entries.map((e) {
      final from = e['from'] ?? '00:00';
      final to = e['to'] ?? '00:00';
      final fromParts = from.split(':');
      final toParts = to.split(':');
      final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, int.parse(fromParts[0]), int.parse(fromParts[1]));
      final end = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, int.parse(toParts[0]), int.parse(toParts[1]));
      return _Block(name: e['event'] ?? '', start: start, end: end);
    }).toList();
  }

  Future<void> _saveDayToFirestore() async {
    try {
      final service = ref.read(programFirestoreServiceProvider);
      final key = _dayKeyForSelected();
      // Build a base week map from cached data or default empty weekdays
      final base = <String, List<Map<String, String>>>{};
      if (_latestWeekProgram != null) {
        for (final e in _latestWeekProgram!.entries) {
          base[e.key] = List<Map<String, String>>.from(e.value.map((m) => Map<String, String>.from(m)));
        }
      } else {
        for (final d in ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']) {
          base[d] = <Map<String, String>>[];
        }
      }
      final updated = Map<String, List<Map<String, String>>>.from(base);
      updated[key] = _serializeBlocksForDay();
      await service.setWeekProgram(updated);
      // update local cache
      setState(() {
        _latestWeekProgram = updated;
        _dirtyDays.remove(key);
        _localDrafts.remove(key);
      });
      if (mounted) showCustomSnackBar(context, translation(context: context, 'Saved'));
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'Error saving: $e');
    }
  }

  Future<void> _deleteBlock(_Block block) async {
    setState(() {
      _blocks.remove(block);
      _editing = null;
      _localDrafts[_dayKeyForSelected()] = _blocks.map((b) => b.copyWith()).toList();
      _dirtyDays.add(_dayKeyForSelected());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSlots = (_endHour - _startHour) * (60 ~/ _slotMinutes);
    final weekProgramAsync = ref.watch(weekProgramProvider);
    weekProgramAsync.whenData((map) {
      // cache latest map
      _latestWeekProgram = map.map((k, v) => MapEntry(k, v.map((e) => Map<String,String>.from(e)).toList()));
      // load for day if not already loaded (or if no local draft present)
      final key = _dayKeyForSelected();
      if ((_loadedDay == null || !_isSameDay(_loadedDay!, _selectedDay)) && !_localDrafts.containsKey(key)) {
        final entries = _latestWeekProgram?[key] ?? [];
        setState(() {
          _blocks.clear();
          _blocks.addAll(_deserializeBlocksForEntries(entries));
          _loadedDay = _selectedDay;
        });
      }
      // if we have a local draft for this day, load it instead (do not overwrite)
      if (_localDrafts.containsKey(key) && (_loadedDay == null || !_isSameDay(_loadedDay!, _selectedDay))) {
        setState(() {
          _blocks.clear();
          _blocks.addAll(_localDrafts[key]!.map((b) => b.copyWith()));
          _loadedDay = _selectedDay;
        });
      }
    });
    // compute editor position and ensure visible if editing
    double? editorTop;
    const double editorHeight = 160.0;
    if (_editing != null) {
      final rawTop = _slotToDY(((_editing!.end.hour - _startHour) * 60 + _editing!.end.minute) ~/ _slotMinutes) + 6;
      final maxTop = totalSlots * _slotHeight - editorHeight;
      editorTop = math.min(rawTop, maxTop);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && editorTop != null) {
          final desiredScroll = (editorTop - 80).clamp(0.0, _scroll.position.maxScrollExtent);
          _scroll.animateTo(desiredScroll, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context: context, 'Program Organisation')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: ToggleButtons(
              isSelected: _slotOptions.map((o) => o == _slotMinutes).toList(),
              onPressed: (idx) {
                setState(() {
                  _slotMinutes = _slotOptions[idx];
                  // clear loaded day so grid reloads with new slot density
                  _loadedDay = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              selectedBorderColor: theme.colorScheme.primary.withAlpha((0.9 * 255).round()),
              borderColor: theme.colorScheme.onSurface.withAlpha((0.12 * 255).round()),
              fillColor: theme.colorScheme.primary.withAlpha((0.14 * 255).round()),
              color: theme.colorScheme.onSurface.withAlpha((0.85 * 255).round()),
              selectedColor: theme.colorScheme.onPrimary,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
              children: _slotOptions.map((o) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('$o', style: theme.textTheme.bodyMedium),
              )).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(builder: (ctx) {
        final currentKey = _dayKeyForSelected();
        final dirty = _dirtyDays.contains(currentKey);
        if (!dirty) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () async {
            await _saveDayToFirestore();
          },
          label: Text(translation(context: context, 'Save')),
          icon: const Icon(Icons.save),
        );
      }),
      body: Column(
        children: [
          // Top day label removed (chip shows selected day)
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (ctx, i) {
                final day = _startOfWeek(_selectedDay).add(Duration(days: i));
                final sel = _isSameDay(day, _selectedDay);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    selected: sel,
                    label: Text(DateFormat.E().format(day)),
                    onSelected: (_) {
                      // Close the inline editor first (apply any pending edits)
                      if (_editing != null) {
                        _editing!.name = _editController.text.trim();
                      }

                      // Persist current day's local draft before switching days
                      final curKey = _dayKeyForSelected();
                      _localDrafts[curKey] = _blocks.map((b) => b.copyWith()).toList();
                      _dirtyDays.add(curKey);

                      // Switch selected day and load either a local draft (if present)
                      // or the cached week program entries.
                      setState(() {
                        _editing = null;
                        _selectedDay = day;
                        final key = DateFormat.EEEE().format(day);
                        if (_localDrafts.containsKey(key)) {
                          _blocks.clear();
                          _blocks.addAll(_localDrafts[key]!.map((b) => b.copyWith()));
                        } else {
                          final entries = _latestWeekProgram?[key] ?? [];
                          _blocks.clear();
                          _blocks.addAll(_deserializeBlocksForEntries(entries));
                        }
                        _loadedDay = day;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                    onLongPressStart: (details) {
                  if (_editing != null) return;
                  _startAt(details.localPosition);
                },
                onLongPressMoveUpdate: (details) {
                  if (_editing != null) return;
                  _updateAt(details.localPosition);
                },
                onLongPressEnd: (_) {
                  if (_editing != null) return;
                  _endAt();
                },
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: SizedBox(
                    // add extra bottom padding when editing to avoid pixel overflow
                    height: totalSlots * _slotHeight + (_editing != null ? 200 : 0),
                    child: Row(
                      children: [
                        // Time gutter
                        Container(
                          width: 72,
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.02 * 255).round()),
                          child: Column(
                            children: List.generate(totalSlots, (idx) {
                              final isHour = idx % (60 ~/ _slotMinutes) == 0;
                              return SizedBox(
                                height: _slotHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: isHour
                                      ? Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            '${(_startHour + idx ~/ (60 ~/ _slotMinutes)).toString().padLeft(2, '0')}:00',
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.9 * 255).round())),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Calendar column
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Grid
                              Column(
                                children: List.generate(totalSlots, (idx) {
                                  final isHour = idx % (60 ~/ _slotMinutes) == 0;
                                  return Container(
                                    height: _slotHeight,
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withAlpha(((isHour ? 0.32 : 0.12) * 255).round()), width: isHour ? 1.0 : 0.6)),
                                    ),
                                  );
                                }),
                              ),
                              // Side-by-side layout for overlapping blocks
                              Builder(builder: (ctx) {
                                final calendarWidth = constraints.maxWidth;
                                const contentPadding = 8.0;
                                const colInnerGutter = 8.0;
                                final availableWidth = (calendarWidth - contentPadding * 2).clamp(0.0, double.infinity);

                                // Build connected groups of overlapping events so columns are computed per-group
                                final visible = List<_Block>.from(_blocks)..sort((a, b) => a.start.compareTo(b.start));
                                // build overlap graph
                                final Map<int, List<int>> adj = {};
                                for (var i = 0; i < visible.length; i++) {
                                  adj[i] = [];
                                }
                                for (var i = 0; i < visible.length; i++) {
                                  for (var j = i + 1; j < visible.length; j++) {
                                    final a = visible[i];
                                    final b = visible[j];
                                    if (a.end.isAfter(b.start) && a.start.isBefore(b.end)) {
                                      adj[i]!.add(j);
                                      adj[j]!.add(i);
                                    }
                                  }
                                }

                                // find connected components
                                final List<List<int>> groups = [];
                                final visited = List<bool>.filled(visible.length, false);
                                for (var i = 0; i < visible.length; i++) {
                                  if (visited[i]) continue;
                                  final stack = [i];
                                  final comp = <int>[];
                                  while (stack.isNotEmpty) {
                                    final cur = stack.removeLast();
                                    if (visited[cur]) continue;
                                    visited[cur] = true;
                                    comp.add(cur);
                                    for (final nb in adj[cur]!) {
                                      if (!visited[nb]) stack.add(nb);
                                    }
                                  }
                                  groups.add(comp);
                                }

                                final List<Widget> positioned = [];
                                for (final group in groups) {
                                  // sort group indices by start
                                  group.sort((a, b) => visible[a].start.compareTo(visible[b].start));
                                  final List<DateTime> colEndsG = [];
                                  final Map<int, int> assignG = {};
                                  for (final idx in group) {
                                    final b = visible[idx];
                                    final found = colEndsG.indexWhere((end) => !end.isAfter(b.start));
                                    if (found >= 0) {
                                      colEndsG[found] = b.end;
                                      assignG[idx] = found;
                                    } else {
                                      colEndsG.add(b.end);
                                      assignG[idx] = colEndsG.length - 1;
                                    }
                                  }
                                  final groupCols = colEndsG.length.clamp(1, visible.length);
                                  final colWidth = (availableWidth / groupCols);
                                  for (final idx in group) {
                                    final b = visible[idx];
                                    final startSlot = ((b.start.hour - _startHour) * 60 + b.start.minute) ~/ _slotMinutes;
                                    final endSlot = ((b.end.hour - _startHour) * 60 + b.end.minute) ~/ _slotMinutes;
                                    final top = _slotToDY(startSlot);
                                    final height = (_slotToDY(endSlot) - _slotToDY(startSlot)).clamp(_slotHeight, double.infinity);
                                    final colIdx = assignG[idx] ?? 0;
                                    final left = contentPadding + colIdx * colWidth;
                                    final right = contentPadding + (groupCols - colIdx - 1) * (colWidth + colInnerGutter);
                                    positioned.add(Positioned(
                                      left: left,
                                      right: right,
                                      top: top,
                                      height: height,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_editing != null) return;
                                            setState(() {
                                              _editing = b;
                                              _editController.text = b.name;
                                            });
                                          },
                                          onLongPressStart: (details) => _onBlockLongPressStart(b, details),
                                          onLongPressMoveUpdate: (details) => _onBlockLongPressMoveUpdate(details),
                                          onLongPressEnd: (details) => _onBlockLongPressEnd(details),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withAlpha((0.18 * 255).round()),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: theme.colorScheme.primary.withAlpha((0.7 * 255).round())),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Builder(builder: (ctx) {
                                              final isSingleSlot = height <= _slotHeight + 0.5;
                                              final title = b.name.isEmpty ? translation(context: context, 'New Program') : b.name;
                                              final timeRange = '${DateFormat('HH:mm').format(b.start)} - ${DateFormat('HH:mm').format(b.end)}';
                                              if (isSingleSlot) {
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(title, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(timeRange, style: theme.textTheme.labelSmall),
                                                  ],
                                                );
                                              }
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(title, style: theme.textTheme.bodyMedium),
                                                  const SizedBox(height: 4),
                                                  Text(timeRange, style: theme.textTheme.labelSmall),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      )
                                    ));
                                  }
                                }
                                return Positioned.fill(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: positioned,
                                  ),
                                );
                              }),
                              // Temp block while dragging
                              if (_tempBlock != null)
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  top: _slotToDY(((_tempBlock!.start.hour - _startHour) * 60 + _tempBlock!.start.minute) ~/ _slotMinutes),
                                  height: ((_tempBlock!.end.difference(_tempBlock!.start).inMinutes) / _slotMinutes) * _slotHeight,
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: Container(
                                      decoration: BoxDecoration(color: theme.colorScheme.primary.withAlpha((0.22 * 255).round()), borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              // Inline editor (conditional Positioned)
                              if (_editing != null) ...[
                                // A full-screen tap detector (under the editor) so taps
                                // outside the editor close it.
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      // Apply edits locally and close (same as Close button)
                                      setState(() {
                                        if (_editing != null) {
                                          _editing!.name = _editController.text.trim();
                                        }
                                        _editing = null;
                                        _localDrafts[_dayKeyForSelected()] = _blocks.map((b) => b.copyWith()).toList();
                                        _dirtyDays.add(_dayKeyForSelected());
                                      });
                                    },
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  top: editorTop ?? 0,
                                  child: _InlineEditor(
                                    start: _editing!.start,
                                    end: _editing!.end,
                                    controller: _editController,
                                    onApply: () {
                                      setState(() {
                                        _editing!.name = _editController.text.trim();
                                        _editing = null;
                                        _localDrafts[_dayKeyForSelected()] = _blocks.map((b) => b.copyWith()).toList();
                                        _dirtyDays.add(_dayKeyForSelected());
                                      });
                                    },
                                    onDelete: () {
                                      if (_editing != null) _deleteBlock(_editing!);
                                    },
                                  ),
                                ),
                              ],
 
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Block {
  String name;
  DateTime start;
  DateTime end;

  _Block({required this.name, required this.start, required this.end});

  _Block copyWith({String? name, DateTime? start, DateTime? end}) => _Block(name: name ?? this.name, start: start ?? this.start, end: end ?? this.end);
}

class _InlineEditor extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final TextEditingController controller;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const _InlineEditor({required this.start, required this.end, required this.controller, required this.onApply, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}', style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: translation(context: context, 'Title')),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onApply, child: Text(translation(context: context, 'Close'))),
                const SizedBox(width: 8),
                TextButton(onPressed: onDelete, child: Text(translation(context: context, 'Delete'), style: TextStyle(color: theme.colorScheme.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _startOfWeek(DateTime d) {
  final wd = d.weekday; // Mon=1
  return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;