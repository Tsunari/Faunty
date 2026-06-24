import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';
import 'package:faunty/features/lists/presentation/controllers/custom_list_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/translation_helper.dart';

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
                final res = await showDialog<String?>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Center(
                      child: Text(
                        translation(context: ctx, 'Edit event'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    content: TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(translation(context: ctx, 'Cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                        child: Text(translation(context: ctx, 'Save')),
                      ),
                    ],
                  ),
                );
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