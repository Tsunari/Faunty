import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';
import 'package:faunty/features/lists/presentation/controllers/custom_list_provider.dart';
import 'package:faunty/core/widgets/table_widget.dart';

final editModeProvider = StateProvider.family<bool, String>(
  (ref, listId) => false,
);

// Provider to trigger save from parent
final saveChangesProvider = StateProvider.family<int, String>(
  (ref, listId) => 0,
);

// Provider to trigger cancel from parent
final cancelChangesProvider = StateProvider.family<int, String>(
  (ref, listId) => 0,
);

class AssignmentListWidget extends ConsumerStatefulWidget {
  final String placeId;
  final CustomList list;
  const AssignmentListWidget({
    super.key,
    required this.placeId,
    required this.list,
  });

  @override
  ConsumerState<AssignmentListWidget> createState() =>
      _AssignmentListWidgetState();
}

class _AssignmentListWidgetState extends ConsumerState<AssignmentListWidget> {
  Map<String, dynamic> editedItems = {}; // Track edited values by item ID
  bool isSaving = false;

  void _stageEdit(
    String id,
    Map<String, dynamic> patch, {
    bool overwrite = false,
  }) {
    if (overwrite) {
      editedItems[id] = Map<String, dynamic>.from(patch);
      return;
    }

    final existing = Map<String, dynamic>.from(
      editedItems[id] as Map<String, dynamic>? ?? {},
    );

    // If this item was newly added and we mark delete, drop it entirely
    if (existing.containsKey('_add') && patch.containsKey('_delete')) {
      editedItems.remove(id);
      return;
    }

    existing.addAll(patch);
    editedItems[id] = existing;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _saveChanges() async {
    if (isSaving || editedItems.isEmpty) return;

    if (mounted) setState(() => isSaving = true);
    try {
      final actions = ref.read(customListActionsProvider);

      // Process all edited items
      for (final entry in editedItems.entries) {
        final itemId = entry.key;
        final data = entry.value as Map<String, dynamic>;

        if (data.containsKey('_delete')) {
          // Delete item
          if (!itemId.startsWith('tmp_')) {
            await actions.deleteItem(widget.placeId, widget.list.id, itemId);
          }
        } else if (data.containsKey('_add')) {
          // Add new item
          final payload = data['payload'] as Map<String, dynamic>;
          final order = data['order'] as int;
          await actions.addItem(
            widget.placeId,
            widget.list.id,
            payload,
            order: order,
          );
        } else {
          // Update existing item
          await actions.updateItem(
            widget.placeId,
            widget.list.id,
            itemId,
            data,
          );
        }
      }

      editedItems.clear();
      if (mounted) showCustomSnackBar(context, 'Changes saved successfully');
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'Error saving changes: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _cancelChanges() {
    setState(() {
      editedItems.clear();
    });
    ref.read(editModeProvider(widget.list.id).notifier).state = false;
  }

  List<ListItem> _applyPendingEdits(List<ListItem> items) {
    if (editedItems.isEmpty) return items;

    final result = <ListItem>[];

    // Apply edits and filter out deleted items
    for (final item in items) {
      if (editedItems.containsKey(item.id)) {
        final edit = editedItems[item.id] as Map<String, dynamic>;
        if (edit.containsKey('_delete')) {
          continue; // Skip deleted items
        } else {
          // Merge edit data with existing item
          final updatedPayload = edit.containsKey('payload')
              ? (edit['payload'] as Map<String, dynamic>)
              : item.payload;
          final updatedOrder = edit.containsKey('order')
              ? (edit['order'] as int)
              : item.order;

          result.add(
            ListItem(
              id: item.id,
              order: updatedOrder,
              payload: updatedPayload,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ),
          );
        }
      } else {
        result.add(item);
      }
    }

    // Add new items
    for (final entry in editedItems.entries) {
      final data = entry.value as Map<String, dynamic>;
      if (data.containsKey('_add')) {
        result.add(
          ListItem(
            id: entry.key,
            order: data['order'] as int,
            payload: data['payload'] as Map<String, dynamic>,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Re-sort after applying edits
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final editMode = ref.watch(editModeProvider(widget.list.id));

    // Listen to edit mode changes to clear edits when exiting
    ref.listen(editModeProvider(widget.list.id), (previous, next) {
      if (previous == true && next == false && mounted) {
        // Clear any unsaved edits when exiting edit mode
        setState(() {
          editedItems.clear();
        });
      }
    });

    // Listen for save trigger from parent
    ref.listen(saveChangesProvider(widget.list.id), (previous, next) {
      if (next != previous && mounted) {
        _saveChanges().then((_) {
          ref.read(editModeProvider(widget.list.id).notifier).state = false;
        });
      }
    });

    // Listen for cancel trigger from parent
    ref.listen(cancelChangesProvider(widget.list.id), (previous, next) {
      if (next != previous && mounted) {
        _cancelChanges();
      }
    });

    final itemsAsync = ref.watch(
      customListItemsProvider(ListKey(widget.placeId, widget.list.id)),
    );

    return itemsAsync.when(
      data: (items) {
        // Always use fresh data from stream, sorted by order
        final sortedItems = List<ListItem>.from(items);
        sortedItems.sort((a, b) => a.order.compareTo(b.order));

        // Apply pending edits on top of stream data for immediate UI feedback
        final currentItems = _applyPendingEdits(sortedItems);
        // Build table items and mapping for row/subsection lookups
        final List<dynamic> tableItems = [];
        final List<(ListItem, int?)> rowPairs =
            []; // flat row index -> (item, rowIndex)
        final Map<int, ListItem> subsectionIndexMap =
            {}; // subsection itemIndex -> ListItem

        for (final item in currentItems) {
          final payload = item.payload;

          if (payload['type'] == 'subsection' && payload['rows'] != null) {
            final rows = (payload['rows'] as List)
                .map(
                  (rowData) => Assignment(
                    left: rowData['left'] as String? ?? '',
                    right: rowData['right'] as String? ?? '',
                    extras: rowData['extras'] ?? [],
                  ),
                )
                .toList();

            final sub = Subsection(
              title: payload['title'] as String? ?? '',
              rows: rows,
            );

            final subsectionIndex = tableItems.length;
            tableItems.add(sub);
            subsectionIndexMap[subsectionIndex] = item;

            for (int i = 0; i < sub.rows.length; i++) {
              rowPairs.add((item, i));
            }
          } else {
            final assignment = Assignment(
              left: payload['left'] as String? ?? '',
              right: payload['right'] as String? ?? '',
              extras: payload['extras'] ?? [],
            );
            tableItems.add(assignment);
            rowPairs.add((item, null));
          }
        }
        return Scaffold(
          body: TableWidget(
            isCellDirty: (index, left) {
              final (item, rowIndex) = rowPairs[index];
              if (!editedItems.containsKey(item.id)) return false;
              final edit = editedItems[item.id] as Map<String, dynamic>;
              if (edit.containsKey('_add')) return true;
              final payload = edit['payload'] as Map<String, dynamic>?;
              if (payload == null) return false;
              if (rowIndex == null) {
                return payload.containsKey(left ? 'left' : 'right');
              } else {
                final rows = payload['rows'] as List?;
                if (rows == null || rowIndex >= rows.length) return false;
                final originalRows = item.payload['rows'] as List?;
                if (originalRows == null || rowIndex >= originalRows.length) return true;
                final cellKey = left ? 'left' : 'right';
                return rows[rowIndex][cellKey] != originalRows[rowIndex][cellKey];
              }
            },
            isSubsectionDirty: (subsectionIndex) {
              final item = subsectionIndexMap[subsectionIndex];
              if (item == null) return false;
              if (!editedItems.containsKey(item.id)) return false;
              final edit = editedItems[item.id] as Map<String, dynamic>;
              if (edit.containsKey('_add')) return true;
              final payload = edit['payload'] as Map<String, dynamic>?;
              return payload?.containsKey('title') ?? false;
            },
            items: tableItems,
            showColumnHeaders: false,
            editMode: editMode,
            onReorder: editMode
                ? (oldIndex, newIndex) async {
                    if (oldIndex == newIndex) return;
                    final reordered = List<ListItem>.from(currentItems);
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);

                    for (int i = 0; i < reordered.length; i++) {
                      if (reordered[i].order != i) {
                        _stageEdit(reordered[i].id, {'order': i});
                      }
                    }

                    setState(() {});
                  }
                : null,
            onSave: editMode
                ? (index, left, newValue) async {
                    final (item, rowIndex) = rowPairs[index];
                    final newPayload = Map<String, dynamic>.from(item.payload);

                    if (rowIndex == null) {
                      // Assignment
                      newPayload[left ? 'left' : 'right'] = newValue;
                    } else {
                      // Row in Subsection
                      final rows = List<Map<String, dynamic>>.from(
                        (newPayload['rows'] as List).map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                      );
                      rows[rowIndex][left ? 'left' : 'right'] = newValue;
                      newPayload['rows'] = rows;
                    }

                    setState(() {
                      _stageEdit(item.id, {'payload': newPayload});
                    });
                  }
                : null,
            onDeleteAssignment: editMode
                ? (index) async {
                    final (item, rowIndex) = rowPairs[index];
                    if (rowIndex == null) {
                      // Delete the entire assignment item
                      setState(() {
                        if (item.id.startsWith('tmp_')) {
                          editedItems.remove(item.id);
                        } else {
                          _stageEdit(item.id, {'_delete': true});
                        }
                      });
                    } else {
                      // Delete a row from subsection
                      final rows = List<Map<String, dynamic>>.from(
                        (item.payload['rows'] as List).map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                      );
                      rows.removeAt(rowIndex);
                      if (rows.isEmpty) {
                        // If no rows left, delete the subsection
                        setState(() {
                          _stageEdit(item.id, {'_delete': true});
                        });
                      } else {
                        // Update subsection with one less row
                        final newPayload = Map<String, dynamic>.from(
                          item.payload,
                        );
                        newPayload['rows'] = rows;
                        setState(() {
                          _stageEdit(item.id, {'payload': newPayload});
                        });
                      }
                    }
                  }
                : null,
            onDeleteSubsection: editMode
                ? (subsectionIndex) async {
                    final item = subsectionIndexMap[subsectionIndex];
                    if (item != null) {
                      setState(() {
                        if (item.id.startsWith('tmp_')) {
                          editedItems.remove(item.id);
                        } else {
                          _stageEdit(item.id, {'_delete': true});
                        }
                      });
                    }
                  }
                : null,
            onSaveSubsection: editMode
                ? (subsectionIndex, newTitle) async {
                    final item = subsectionIndexMap[subsectionIndex];
                    if (item != null) {
                      final newPayload = Map<String, dynamic>.from(
                        item.payload,
                      );
                      newPayload['title'] = newTitle;
                      setState(() {
                        _stageEdit(item.id, {'payload': newPayload});
                      });
                    }
                  }
                : null,
            onAddAssignment: editMode
                ? () {
                    // Create a new assignment item
                    final tmpId = 'tmp_${const Uuid().v4()}';
                    final newOrder = currentItems.length;
                    setState(() {
                      _stageEdit(tmpId, {
                        '_add': true,
                        'order': newOrder,
                        'payload': {'left': '', 'right': ''},
                      }, overwrite: true);
                    });
                  }
                : null,
            onAddSubsection: editMode
                ? () {
                    // Create a new subsection item
                    final tmpId = 'tmp_${const Uuid().v4()}';
                    final newOrder = currentItems.length;
                    setState(() {
                      _stageEdit(tmpId, {
                        '_add': true,
                        'order': newOrder,
                        'payload': {
                          'type': 'subsection',
                          'title': 'New Subsection',
                          'rows': [
                            {'left': '', 'right': ''},
                          ],
                        },
                      }, overwrite: true);
                    });
                  }
                : null,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}