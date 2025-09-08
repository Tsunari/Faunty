import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
import 'package:faunty/components/table_widget.dart';

final editModeProvider = StateProvider.family<bool, String>((ref, listId) => false);

class AssignmentListWidget extends ConsumerStatefulWidget {
  final String placeId;
  final CustomList list;
  const AssignmentListWidget({super.key, required this.placeId, required this.list});

  @override
  ConsumerState<AssignmentListWidget> createState() => _AssignmentListWidgetState();
}

class _AssignmentListWidgetState extends ConsumerState<AssignmentListWidget> {
  List<ListItem>? localItems;
  List<Future<void> Function()> pendingSaves = [];
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final editMode = ref.watch(editModeProvider(widget.list.id));
    final itemsAsync = ref.watch(customListItemsProvider(ListKey(widget.placeId, widget.list.id)));
    
    // Handle edit mode changes
    if (!editMode && localItems != null) {
      // Exiting edit mode, discard changes
      localItems = null;
      pendingSaves.clear();
      isSaving = false;
    }
    
    return itemsAsync.when(
      data: (items) {
        if (localItems == null) {
          localItems = List.from(items);
        }
        // Use localItems for building tableItems
        final currentItems = localItems!;
        // Convert ListItem to table items (Assignment or Subsection)
        List<dynamic> tableItems = [];
        List<(ListItem, int?)> pairs = [];
        for (final item in currentItems) {
          final payload = item.payload;
          if (payload['type'] == 'subsection' && payload['rows'] != null) {
            final sub = Subsection(
              title: payload['title'] as String? ?? '',
              rows: (payload['rows'] as List).map((rowData) => Assignment(
                left: rowData['left'] as String? ?? '',
                right: rowData['right'] as String? ?? '',
                extras: rowData['extras'] ?? [],
              )).toList(),
            );
            tableItems.add(sub);
            pairs.add((item, null));
            for (int i = 0; i < sub.rows.length; i++) {
              pairs.add((item, i));
            }
          } else {
            final assignment = Assignment(
              left: payload['left'] as String? ?? '',
              right: payload['right'] as String? ?? '',
              extras: payload['extras'] ?? [],
            );
            tableItems.add(assignment);
            pairs.add((item, null));
          }
        }
        return Scaffold(
          body: TableWidget(
            items: tableItems,
            showColumnHeaders: false,
            editMode: editMode,
            onSave: editMode ? (index, left, newValue) async {
              final (item, rowIndex) = pairs[index];
              if (rowIndex == null) {
                // Assignment
                item.payload[left ? 'left' : 'right'] = newValue;
              } else {
                // Row in Subsection
                (item.payload['rows'] as List)[rowIndex][left ? 'left' : 'right'] = newValue;
              }
              pendingSaves.add(() => ref.read(customListActionsProvider).updateItem(widget.placeId, widget.list.id, item.id, {'payload': item.payload}));
            } : null,
            onDeleteAssignment: editMode ? (index) async {
              final (item, rowIndex) = pairs[index];
              if (rowIndex == null) {
                // Delete the entire assignment item
                pendingSaves.add(() => ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id));
                localItems!.remove(item);
                setState(() {});
              } else {
                // Delete a row from subsection
                final rows = item.payload['rows'] as List;
                rows.removeAt(rowIndex);
                if (rows.isEmpty) {
                  // If no rows left, delete the subsection item
                  pendingSaves.add(() => ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id));
                  localItems!.remove(item);
                } else {
                  pendingSaves.add(() => ref.read(customListActionsProvider).updateItem(widget.placeId, widget.list.id, item.id, {'payload': item.payload}));
                }
                setState(() {});
              }
            } : null,
            onDeleteSubsection: editMode ? (subsectionIndex) async {
              // Find the item corresponding to the subsection
              int currentIndex = 0;
              for (final item in currentItems) {
                if (item.payload['type'] == 'subsection') {
                  if (currentIndex == subsectionIndex) {
                    pendingSaves.add(() => ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id));
                    localItems!.remove(item);
                    setState(() {});
                    return;
                  }
                  currentIndex++;
                }
              }
            } : null,
            onSaveSubsection: editMode ? (subsectionIndex, newTitle) async {
              // Find the item corresponding to the subsection
              int currentIndex = 0;
              for (final item in currentItems) {
                if (item.payload['type'] == 'subsection') {
                  if (currentIndex == subsectionIndex) {
                    item.payload['title'] = newTitle;
                    pendingSaves.add(() => ref.read(customListActionsProvider).updateItem(widget.placeId, widget.list.id, item.id, {'payload': item.payload}));
                    return;
                  }
                  currentIndex++;
                }
              }
            } : null,
            onAddAssignment: editMode ? () {
              // Create a new assignment item
              final newItem = ListItem(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                order: localItems!.length,
                payload: {'left': '', 'right': ''},
                createdAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
              );
              localItems!.add(newItem);
              pendingSaves.add(() => ref.read(customListActionsProvider).addItem(widget.placeId, widget.list.id, newItem.payload));
              setState(() {});
            } : null,
            onAddSubsection: editMode ? () {
              // Create a new subsection item
              final newItem = ListItem(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                order: localItems!.length,
                payload: {
                  'type': 'subsection',
                  'title': 'New Subsection',
                  'rows': [{'left': '', 'right': ''}]
                },
                createdAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
              );
              localItems!.add(newItem);
              pendingSaves.add(() => ref.read(customListActionsProvider).addItem(widget.placeId, widget.list.id, newItem.payload));
              setState(() {});
            } : null,
          ),
          floatingActionButton: editMode ? FloatingActionButton(
            onPressed: isSaving ? null : () async {
              setState(() => isSaving = true);
              try {
                if (pendingSaves.isNotEmpty) {
                  // Save all pending changes
                  for (final save in pendingSaves) {
                    await save();
                  }
                  pendingSaves.clear();
                  // Reset local items to sync with Firestore
                  localItems = null;
                }
                // Always exit edit mode
                ref.read(editModeProvider(widget.list.id).notifier).state = false;
                // Refresh the UI
                setState(() {});
              } catch (e) {
                // Show error if save fails
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save changes: $e')),
                );
              } finally {
                setState(() => isSaving = false);
              }
            },
            child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
          ) : null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

