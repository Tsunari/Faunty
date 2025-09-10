import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../firestore/attendance_firestore_service.dart';
import 'package:faunty/tools/translation_helper.dart';

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

  Future<void> _addInline() async {
    final val = _newCtrl.text.trim();
    if (val.isEmpty) return;
    // create via service to get stable id
    final id = await AttendanceFirestoreService(widget.placeId).addAttendanceMetaItem(val);
    setState(() {
  _items.add({'id': id, 'name': val});
      _newCtrl.clear();
    });
    await _save();
  }

  Future<void> _startEdit(int idx) async {
  _editingIndex = idx;
  _editCtrls[idx] = TextEditingController(text: _items[idx]['name'] as String? ?? '');
    setState(() {});
  }

  Future<void> _commitEdit(int idx) async {
    final ctrl = _editCtrls[idx];
    if (ctrl == null) return;
    final val = ctrl.text.trim();
    if (val.isEmpty) return _cancelEdit(idx);
    if ((_items[idx]['name'] as String? ?? '') != val) {
      final id = _items[idx]['id'] as String;
      await AttendanceFirestoreService(widget.placeId).renameAttendanceMetaItem(id, val);
      setState(() => _items[idx]['name'] = val);
      await _save();
    }
    _cancelEdit(idx);
  }

  void _cancelEdit(int idx) {
    _editCtrls[idx]?.dispose();
    _editCtrls.remove(idx);
    _editingIndex = null;
    setState(() {});
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
    setState(() {
      _items.removeAt(index);
    });
    await AttendanceFirestoreService(widget.placeId).removeAttendanceMetaItem(id);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(translation(context: context, 'Manage tracking items'))),
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
                                        if (!inEdit)
                                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEdit(idx)),
                                        if (inEdit) ...[
                                          IconButton(icon: const Icon(Icons.check), onPressed: () => _commitEdit(idx)),
                                          IconButton(icon: const Icon(Icons.close), onPressed: () => _cancelEdit(idx)),
                                        ],
                                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeItem(idx)),
                                      ]),
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
