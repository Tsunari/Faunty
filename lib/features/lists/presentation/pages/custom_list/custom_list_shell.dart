import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';
import 'package:faunty/features/lists/presentation/controllers/custom_list_provider.dart';
import 'package:faunty/core/utils/icon_registry.dart';
import 'package:faunty/features/lists/presentation/pages/custom_list/assignment_list_widget.dart';

class CustomListShell extends ConsumerWidget {
  final String placeId;
  final CustomList list;
  final Widget child;
  final VoidCallback? onEditList;
  final ValueChanged<bool>? onEditModeChanged;

  const CustomListShell({
    super.key,
    required this.placeId,
    required this.list,
    required this.child,
    this.onEditList,
    this.onEditModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(customListServiceProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
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
                  if (list.icon != null && list.icon!.kind == 'material')
                    Icon(iconFromSpec(list.icon)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      list.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  RoleGate(
                    minRole: UserRole.baskan,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isEditMode = ref.watch(editModeProvider(list.id));

                        if (isEditMode) {
                          // Show Save and Cancel buttons in edit mode
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // Trigger cancel via provider
                                  ref.read(cancelChangesProvider(list.id).notifier).state++;
                                },
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Cancel'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Trigger save via provider
                                  ref.read(saveChangesProvider(list.id).notifier).state++;
                                },
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('Save'),
                              ),
                            ],
                          );
                        } else {
                          // Show Edit button when not in edit mode
                          return IconButton(
                            onPressed: () {
                              ref.read(editModeProvider(list.id).notifier).state = true;
                              onEditModeChanged?.call(true);
                            },
                            icon: const Icon(Icons.edit),
                            tooltip: 'Enter edit mode',
                          );
                        }
                      },
                    ),
                  ),
                  RoleGate(
                    minRole: UserRole.baskan,
                    child: IconButton(
                      onPressed:
                          onEditList ??
                          () async {
                            final ctrl = TextEditingController(
                              text: list.title,
                            );
                            final res = await showDialog<String?>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Edit list'),
                                content: TextField(controller: ctrl),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(ctrl.text.trim()),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (res != null && res.isNotEmpty) {
                              await svc.updateList(placeId, list.id, {
                                'title': res,
                              });
                            }
                          },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    ),
    ),
    );
  }
}