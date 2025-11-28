import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/components/icon_picker.dart';
import 'package:faunty/helper/icon_registry.dart';
import 'package:faunty/components/custom_app_bar.dart';

class AddPage extends ConsumerStatefulWidget {
  const AddPage({super.key});

  @override
  ConsumerState<AddPage> createState() => _AddPageState();
}

class _AddPageState extends ConsumerState<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  CustomListType _type = CustomListType.assignment;
  IconSpec _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily); // default list icon (plus)
  String? _editingListId;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.asData?.value;
    final placeId = user?.placeId ?? 'default_place';

    final listsAsync = ref.watch(customListsProvider(placeId));

    return Scaffold(
      appBar: CustomAppBar(
        title: _editingListId == null
            ? 'Create custom list'
            : 'Edit custom list',
        useModern: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // existing lists manager
            Expanded(
              child: listsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return const Center(child: Text('No custom lists yet'));
                  return ListView.separated(
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final l = lists[idx];
                      final iconWidget = l.icon != null && l.icon!.kind == 'material'
                          ? Icon(iconFromSpec(l.icon))
                          : const Icon(Icons.list);
                      return ListTile(
                        leading: iconWidget,
                        title: Text(l.title),
                        subtitle: Text(l.type.toString().split('.').last),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // populate form for edit
                              setState(() {
                                _editingListId = l.id;
                                _titleCtrl.text = l.title;
                                _type = l.type;
                                _icon = l.icon ?? IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                title: const Text('Delete list?'),
                                content: Text('Delete "${l.title}" and all its items?'),
                                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))],
                              ));
                              if (ok == true) {
                                await ref.read(customListServiceProvider).deleteList(placeId, l.id);
                                    // Ensure widget is still mounted before updating UI
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${l.title}')));
                                // clear edit form if it was this list
                                if (_editingListId == l.id) {
                                  setState(() {
                                    _editingListId = null;
                                    _titleCtrl.clear();
                                    _type = CustomListType.assignment;
                                    _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                                  });
                                }
                              }
                            },
                          ),
                        ]),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error loading lists: $e')),
              ),
            ),

            const SizedBox(height: 12),

            // create / edit form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'List title'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Type'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('assignment'),
                        selected: _type == CustomListType.assignment,
                        onSelected: (s) => setState(() => _type = CustomListType.assignment),
                      ),
                      // Temporarily disabled other types
                      ChoiceChip(
                        label: const Text('attendance (coming)'),
                        selected: false,
                        onSelected: null, // Disabled
                      ),
                      ChoiceChip(
                        label: const Text('schedule (coming)'),
                        selected: false,
                        onSelected: null, // Disabled
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Icon'),
                  const SizedBox(height: 6),
                  IconPicker(selected: _icon, onSelected: (ic) => setState(() => _icon = ic)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final svc = ref.read(customListServiceProvider);
                            if (_editingListId == null) {
                              // create
                              final userAsync = ref.read(userProvider);
                              final user = userAsync.asData?.value;
                              final createdBy = user?.uid ?? 'unknown';
                              final now = Timestamp.now();
                              final list = CustomList(
                                id: '',
                                title: _titleCtrl.text.trim(),
                                type: _type,
                                createdBy: createdBy,
                                createdAt: now,
                                order: 9999,
                                visible: true,
                                icon: _icon,
                                meta: {},
                              );
                              await svc.createList(placeId, list);
                                  // Ensure widget is still mounted before updating UI
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created ${list.title}')));
                              _titleCtrl.clear();
                              setState(() => _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily));
                            } else {
                              // update
                              await svc.updateList(placeId, _editingListId!, {
                                'title': _titleCtrl.text.trim(),
                                'type': _type.toString().split('.').last,
                                'icon': _icon.toMap(),
                              });
                                  // Ensure widget is still mounted before updating UI
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated list')));
                              setState(() {
                                _editingListId = null;
                                _titleCtrl.clear();
                                _type = CustomListType.assignment;
                                _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                              });
                            }
                          },
                          child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_editingListId == null ? 'Create' : 'Save')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_editingListId != null)
                        OutlinedButton(onPressed: () {
                          setState(() {
                            _editingListId = null;
                            _titleCtrl.clear();
                            _type = CustomListType.assignment;
                            _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                          });
                        }, child: const Text('Cancel'))
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // IconPicker component is used instead
}
