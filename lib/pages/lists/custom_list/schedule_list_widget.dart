import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleListWidget extends ConsumerWidget {
  final String placeId;
  final CustomList list;
  const ScheduleListWidget({super.key, required this.placeId, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final itemsAsync = ref.watch(customListItemsProvider(ListKey(placeId, list.id)));
    return itemsAsync.when(
      data: (items) {
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final it = items[i];
            final start = (it.payload['startAt'] as Timestamp?)?.toDate();
            final title = it.payload['title'] as String? ?? '';
            return ListTile(
              title: Text(title),
              subtitle: Text(start != null ? start.toString() : 'No time'),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                // quick edit: allow changing title
                final ctrl = TextEditingController(text: title);
                final res = await showDialog<String?>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Edit event'),
                  content: TextField(controller: ctrl),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save'))],
                ));
                if (res != null) {
                  await ref.read(customListServiceProvider).updateItem(placeId, list.id, it.id, {'payload': {...it.payload, 'title': res}, 'updatedAt': FieldValue.serverTimestamp()});
                }
              }),
            );
          }
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
