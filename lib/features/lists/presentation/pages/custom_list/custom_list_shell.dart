import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';
import 'package:faunty/features/lists/presentation/controllers/custom_list_provider.dart';
import 'package:faunty/features/lists/presentation/pages/custom_list/assignment_list_widget.dart';
import 'package:faunty/core/utils/icon_registry.dart';
import 'package:faunty/core/widgets/glass_container.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class CustomListAppBarActions extends ConsumerWidget {
  final String placeId;
  final CustomList list;
  final VoidCallback? onEditList;
  final ValueChanged<bool>? onEditModeChanged;

  const CustomListAppBarActions({
    super.key,
    required this.placeId,
    required this.list,
    this.onEditList,
    this.onEditModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(customListServiceProvider);
    final isEditMode = ref.watch(editModeProvider(list.id));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEditMode) ...[
          TextButton.icon(
            onPressed: () {
              ref.read(cancelChangesProvider(list.id).notifier).state++;
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(translation('Cancel', context: context)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(saveChangesProvider(list.id).notifier).state++;
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(translation('Save', context: context)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
            ),
          ),
        ] else ...[
          IconButton(
            onPressed: () {
              ref.read(editModeProvider(list.id).notifier).state = true;
              onEditModeChanged?.call(true);
            },
            icon: const Icon(Icons.edit_rounded),
            tooltip: translation('Enter edit mode', context: context),
          ),
        ],
        RoleGate(
          minRole: UserRole.baskan,
          child: IconButton(
            onPressed: onEditList ?? () async {
              final ctrl = TextEditingController(
                text: list.title,
              );
              final theme = Theme.of(context);
              final res = await showDialog<String?>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(translation('Edit list', context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: translation('List Title', context: context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(translation('Cancel', context: context)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: Text(translation('Save', context: context)),
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
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ),
      ],
    );
  }
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tabAppBarConfigProvider(list.title).notifier).state = TabAppBarConfig(
        actions: [
          CustomListAppBarActions(
            placeId: placeId,
            list: list,
            onEditList: onEditList,
            onEditModeChanged: onEditModeChanged,
          ),
        ],
      );
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 96, 12, 96),
          child: child,
        ),
      ),
    );
  }
}