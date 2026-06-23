import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/tracking/data/repositories/attendance_firestore_service.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class AttendanceItemsPage extends ConsumerStatefulWidget {
  final String placeId;
  const AttendanceItemsPage({super.key, required this.placeId});

  @override
  ConsumerState<AttendanceItemsPage> createState() => _AttendanceItemsPageState();
}

class _AttendanceItemsPageState extends ConsumerState<AttendanceItemsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final TextEditingController _newCtrl = TextEditingController();
  final Map<int, TextEditingController> _editCtrls = {};
  int? _editingIndex;
  final Set<String> _settingsOpen = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    for (final c in _editCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final meta = await AttendanceFirestoreService(widget.placeId).getAttendanceMeta();
    if (!mounted) return;
    setState(() {
      _items = (meta['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
      _loading = false;
    });
  }

  Future<void> _save() async {
  final meta = await AttendanceFirestoreService(widget.placeId).getAttendanceMeta();
  meta['items'] = _items;
  await AttendanceFirestoreService(widget.placeId).setAttendanceMeta(meta);
  }

  List<int> _ensureWeekdays(Map<String, dynamic> item) {
    final wd = (item['weekdays'] as List?)?.cast<int>();
    if (wd == null || wd.isEmpty) {
      item['weekdays'] = [1, 2, 3, 4, 5, 6, 7];
      return item['weekdays'].cast<int>();
    }
    return wd;
  }

  bool _ensureLateness(Map<String, dynamic> item) {
    if (item['latenessEnabled'] is! bool) {
      item['latenessEnabled'] = false;
    }
    return item['latenessEnabled'] as bool;
  }

  Future<void> _addInline() async {
    final val = _newCtrl.text.trim();
    if (val.isEmpty) return;
    // create via service to get stable id
    final id = await AttendanceFirestoreService(widget.placeId).addAttendanceMetaItem(val);
    if (!mounted) return;
    setState(() {
      _items.add({'id': id, 'name': val});
      _newCtrl.clear();
    });
    await _save();
  }

  Future<void> _startEdit(int idx) async {
    _editingIndex = idx;
    _editCtrls[idx] = TextEditingController(text: _items[idx]['name'] as String? ?? '');
    if (mounted) setState(() {});
  }

  Future<void> _commitEdit(int idx) async {
    final ctrl = _editCtrls[idx];
    if (ctrl == null) return;
    final val = ctrl.text.trim();
    if (val.isEmpty) return _cancelEdit(idx);
    if ((_items[idx]['name'] as String? ?? '') != val) {
      final id = _items[idx]['id'] as String;
      await AttendanceFirestoreService(widget.placeId).renameAttendanceMetaItem(id, val);
      if (!mounted) return;
      setState(() => _items[idx]['name'] = val);
      await _save();
    }
    _cancelEdit(idx);
  }

  void _cancelEdit(int idx) {
    _editCtrls[idx]?.dispose();
    _editCtrls.remove(idx);
    _editingIndex = null;
    if (mounted) setState(() {});
  }

  Future<void> _removeItem(int index) async {
  final name = _items[index]['name'] as String? ?? '';
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translation(context: context, 'Remove tracking item')),
        content: Text('${translation(context: context, 'Remove')} "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(translation(context: context, 'Remove'))),
        ],
      ),
    );
    if (ok != true) return;
    final id = _items[index]['id'] as String;
    if (mounted) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      // if widget is gone, just mutate the list to keep consistency
      _items.removeAt(index);
    }
    await AttendanceFirestoreService(widget.placeId).removeAttendanceMetaItem(id);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Manage tracking items'),
        useModern: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Expanded(
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _items.length,
                              onReorder: (oldIndex, newIndex) async {
                                // Cancel any in-progress edit to avoid controller/key mismatch
                                if (_editingIndex != null) {
                                  _cancelEdit(_editingIndex!);
                                }
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final item = _items.removeAt(oldIndex);
                                  _items.insert(newIndex, item);
                                });
                                await _save();
                              },
                              buildDefaultDragHandles: false,
                              itemBuilder: (context, idx) {
                                final inEdit = _editingIndex == idx;
                                final keyVal = ValueKey(_items[idx]['id'] as String? ?? '${_items[idx]['name']}_$idx');
                                final item = _items[idx];
                                final itemId = (item['id'] as String?) ?? keyVal.value.toString();
                                final isSettingsOpen = _settingsOpen.contains(itemId);
                                return Column(
                                  key: keyVal,
                                  children: [
                                    ListTile(
                                      leading: ReorderableDragStartListener(
                                        index: idx,
                                        child: const Icon(Icons.drag_indicator, color: Colors.grey),
                                      ),
                                      title: inEdit
                                          ? TextField(
                                              controller: _editCtrls[idx],
                                              autofocus: true,
                                              onSubmitted: (_) => _commitEdit(idx),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                            )
                                          : Text(_items[idx]['name'] as String? ?? '', style: theme.textTheme.bodyLarge),
                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                        IconButton(
                                          tooltip: translation(context: context, 'Settings'),
                                          icon: const Icon(Icons.settings),
                                          onPressed: () {
                                            setState(() {
                                              if (isSettingsOpen) {
                                                _settingsOpen.remove(itemId);
                                              } else {
                                                _settingsOpen.add(itemId);
                                              }
                                            });
                                          },
                                        ),
                                        if (!inEdit)
                                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEdit(idx)),
                                        if (inEdit) ...[
                                          IconButton(icon: const Icon(Icons.check), onPressed: () => _commitEdit(idx)),
                                          IconButton(icon: const Icon(Icons.close), onPressed: () => _cancelEdit(idx)),
                                        ],
                                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeItem(idx)),
                                      ]),
                                    ),
                                    if (isSettingsOpen)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(56, 0, 12, 8),
                                        child: Builder(builder: (context) {
                                          final weekdays = _ensureWeekdays(item);
                                          final lateness = _ensureLateness(item);
                                          const fullLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                                          const shortLabels = ['M','T','W','T','F','S','S'];
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(translation(context: context, 'Weekdays'), style: theme.textTheme.bodyMedium),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: List.generate(7, (i) {
                                                  final day = i + 1; // 1..7
                                                  final selected = weekdays.contains(day);
                                                  return Tooltip(
                                                    message: fullLabels[i],
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(16),
                                                      onTap: () async {
                                                        setState(() {
                                                          if (selected) {
                                                            weekdays.remove(day);
                                                          } else {
                                                            weekdays.add(day);
                                                          }
                                                          weekdays.sort();
                                                          item['weekdays'] = List<int>.from(weekdays);
                                                        });
                                                        await _save();
                                                      },
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        alignment: Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: selected ? theme.colorScheme.primary : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(color: selected ? theme.colorScheme.primary : theme.dividerColor),
                                                        ),
                                                        child: Text(
                                                          shortLabels[i],
                                                          style: theme.textTheme.labelMedium?.copyWith(
                                                            color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Text(translation(context: context, 'Lateness'), style: theme.textTheme.bodyMedium),
                                                  const SizedBox(width: 12),
                                                  Switch(
                                                    value: lateness,
                                                    onChanged: (val) async {
                                                      setState(() {
                                                        item['latenessEnabled'] = val;
                                                      });
                                                      await _save();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    const Divider(height: 8),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6.0, 6.0, 0, 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newCtrl,
                                    decoration: InputDecoration(
                                      hintText: translation(context: context, 'Add new item'),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onSubmitted: (_) => _addInline(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addInline,
                                  child: Row(children: [const Icon(Icons.add), const SizedBox(width: 6), Text(translation(context: context, 'Add'))]),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}