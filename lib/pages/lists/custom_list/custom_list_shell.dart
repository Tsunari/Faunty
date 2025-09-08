import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
import 'package:faunty/helper/icon_registry.dart';
import 'assignment_list_widget.dart';

class CustomListShell extends ConsumerWidget {
  final String placeId;
  final CustomList list;
  final Widget child;
  final VoidCallback? onAddItem;
  final VoidCallback? onEditList;
  final ValueChanged<bool>? onEditModeChanged;

  const CustomListShell({super.key, required this.placeId, required this.list, required this.child, this.onAddItem, this.onEditList, this.onEditModeChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(customListServiceProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (list.icon != null && list.icon!.kind == 'material') Icon(iconFromSpec(list.icon)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(list.title, style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                    onPressed: onAddItem ?? () async {
                      final payload = {'left': '', 'right': ''};
                      await svc.addItem(placeId, list.id, payload);
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = ref.read(editModeProvider(list.id));
                      ref.read(editModeProvider(list.id).notifier).state = !current;
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: onEditList ?? () async {
                      final ctrl = TextEditingController(text: list.title);
                      final res = await showDialog<String?>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Edit list'),
                        content: TextField(controller: ctrl),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save'))],
                      ));
                      if (res != null && res.isNotEmpty) {
                        await svc.updateList(placeId, list.id, {'title': res});
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
