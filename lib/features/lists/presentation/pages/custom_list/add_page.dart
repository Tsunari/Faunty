import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';
import 'package:faunty/features/lists/presentation/controllers/custom_list_provider.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/core/widgets/icon_picker.dart';
import 'package:faunty/core/utils/icon_registry.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/core/widgets/custom_confirm_dialog.dart';

class AddPage extends ConsumerStatefulWidget {
  const AddPage({super.key});

  @override
  ConsumerState<AddPage> createState() => _AddPageState();
}

class _AddPageState extends ConsumerState<AddPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  CustomListType _type = CustomListType.assignment;
  IconSpec _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
  String? _editingListId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // rebuild for tab label / icon changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Widget _buildActiveListsTab(BuildContext context, AsyncValue<List<CustomList>> listsAsync, String placeId) {
    final theme = Theme.of(context);
    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_rounded, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  translation('No custom lists yet', context: context),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: lists.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemBuilder: (ctx, idx) {
            final l = lists[idx];
            final iconWidget = l.icon != null && l.icon!.kind == 'material'
                ? Icon(iconFromSpec(l.icon), color: theme.colorScheme.primary)
                : Icon(Icons.list_rounded, color: theme.colorScheme.primary);
            return Card(
              color: theme.colorScheme.surfaceContainerHigh,
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: iconWidget,
                ),
                title: Text(
                  l.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          translation(l.type.toString().split('.').last, context: context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
                      tooltip: translation('Edit list', context: context),
                      onPressed: () {
                        setState(() {
                          _editingListId = l.id;
                          _titleCtrl.text = l.title;
                          _type = l.type;
                          _icon = l.icon ?? IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                        });
                        _tabController.animateTo(1);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                      tooltip: translation('Delete list', context: context),
                      onPressed: () async {
                        final confirm = await showDeleteDialog(context: context, thingToDelete: l.title);
                        if (confirm == true) {
                          await ref.read(customListServiceProvider).deleteList(placeId, l.id);
                          if (!mounted) return;
                          showCustomSnackBar(context, 'Deleted "${l.title}"');
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
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading lists: $e')),
    );
  }

  Widget _buildCreateEditTab(BuildContext context, String placeId) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: translation('List Title', context: context),
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? translation('Please enter a title', context: context)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              translation('Type', context: context),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(translation('Assignment', context: context)),
                  selected: _type == CustomListType.assignment,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (s) => setState(() => _type = CustomListType.assignment),
                ),
                ChoiceChip(
                  label: Text(translation('Attendance (coming soon)', context: context)),
                  selected: false,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: null,
                ),
                ChoiceChip(
                  label: Text(translation('Schedule (coming soon)', context: context)),
                  selected: false,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              translation('Select List Icon', context: context),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: IconPicker(selected: _icon, onSelected: (ic) => setState(() => _icon = ic)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final svc = ref.read(customListServiceProvider);
                      if (_editingListId == null) {
                        final userAsync = ref.read(userProvider);
                        final user = userAsync.asData?.value;
                        final createdBy = user?.uid ?? 'unknown';
                        final now = DateTime.now();
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
                        if (!mounted) return;
                        showCustomSnackBar(context, 'Created "${list.title}"');
                        _titleCtrl.clear();
                        setState(() => _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily));
                        _tabController.animateTo(0);
                      } else {
                        await svc.updateList(placeId, _editingListId!, {
                          'title': _titleCtrl.text.trim(),
                          'type': _type.toString().split('.').last,
                          'icon': _icon.toMap(),
                        });
                        if (!mounted) return;
                        showCustomSnackBar(context, 'Updated list');
                        setState(() {
                          _editingListId = null;
                          _titleCtrl.clear();
                          _type = CustomListType.assignment;
                          _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                        });
                        _tabController.animateTo(0);
                      }
                    },
                    icon: Icon(_editingListId == null ? Icons.add_rounded : Icons.save_rounded),
                    label: Text(_editingListId == null
                        ? translation('Create List', context: context)
                        : translation('Save Changes', context: context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_editingListId != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _editingListId = null;
                        _titleCtrl.clear();
                        _type = CustomListType.assignment;
                        _icon = IconSpec.material(Icons.post_add_outlined.codePoint, fontFamily: Icons.post_add_outlined.fontFamily);
                      });
                      _tabController.animateTo(0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(translation('Cancel', context: context)),
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.asData?.value;
    final placeId = user?.placeId ?? 'default_place';
    final listsAsync = ref.watch(customListsProvider(placeId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translation('Custom Lists', context: context)),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.list_alt_rounded),
                text: translation('Active Lists', context: context),
              ),
              Tab(
                icon: Icon(_editingListId == null ? Icons.add_circle_outline_rounded : Icons.edit_rounded),
                text: _editingListId == null
                    ? translation('Create List', context: context)
                    : translation('Edit List', context: context),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveListsTab(context, listsAsync, placeId),
            _buildCreateEditTab(context, placeId),
          ],
        ),
      ),
    );
  }
}