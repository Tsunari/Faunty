import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Widget build(BuildContext context) {
    final editMode = ref.watch(editModeProvider(widget.list.id));
    final itemsAsync = ref.watch(customListItemsProvider(ListKey(widget.placeId, widget.list.id)));
    return itemsAsync.when(
      data: (items) {
        // Convert ListItem to table items (Assignment or Subsection)
        List<dynamic> tableItems = [];
        List<(ListItem, int?)> pairs = [];
        for (final item in items) {
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
        return TableWidget(
          items: tableItems,
          showColumnHeaders: false,
          editMode: editMode,
          onSave: (index, left, newValue) async {
            final (item, rowIndex) = pairs[index];
            if (rowIndex == null) {
              // Assignment
              item.payload[left ? 'left' : 'right'] = newValue;
            } else {
              // Row in Subsection
              (item.payload['rows'] as List)[rowIndex][left ? 'left' : 'right'] = newValue;
            }
            await ref.read(customListActionsProvider).updateItem(widget.placeId, widget.list.id, item.id, {'payload': item.payload});
          },
          onDeleteAssignment: editMode ? (index) async {
            final (item, rowIndex) = pairs[index];
            if (rowIndex == null) {
              // Delete the entire assignment item
              await ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id);
            } else {
              // Delete a row from subsection
              final rows = item.payload['rows'] as List;
              rows.removeAt(rowIndex);
              if (rows.isEmpty) {
                // If no rows left, delete the subsection item
                await ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id);
              } else {
                await ref.read(customListActionsProvider).updateItem(widget.placeId, widget.list.id, item.id, {'payload': item.payload});
              }
            }
          } : null,
          onDeleteSubsection: editMode ? (subsectionIndex) async {
            // Find the item corresponding to the subsection
            int currentIndex = 0;
            for (final item in items) {
              if (item.payload['type'] == 'subsection') {
                if (currentIndex == subsectionIndex) {
                  await ref.read(customListActionsProvider).deleteItem(widget.placeId, widget.list.id, item.id);
                  return;
                }
                currentIndex++;
              }
            }
          } : null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

