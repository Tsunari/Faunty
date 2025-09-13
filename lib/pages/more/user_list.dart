import 'package:faunty/components/custom_snackbar.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:faunty/components/custom_confirm_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import '../../state_management/firestore_quota_provider.dart';
import '../../models/user_entity.dart';
import '../../models/user_roles.dart';
import 'users_page.dart';

class UserListWithScrollbar extends StatefulWidget {
  final List<UserEntity> users;
  final ColorScheme colorScheme;
  final UserEntity currentUser;
  const UserListWithScrollbar({super.key, required this.users, required this.colorScheme, required this.currentUser});

  @override
  State<UserListWithScrollbar> createState() => UserListWithScrollbarState();
}

class UserListWithScrollbarState extends State<UserListWithScrollbar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superuser:
        return Icons.admin_panel_settings_outlined;
      case UserRole.hoca:
        return Icons.school_outlined;
      case UserRole.baskan:
      case UserRole.talebe:
        return Icons.person_outline;
      case UserRole.user:
        return Icons.person_add_alt_1_outlined;
      case UserRole.spectator:
        return Icons.visibility_outlined;
      case UserRole.archived:
        return Icons.archive_outlined;
      case UserRole.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.users.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: widget.colorScheme.outline.withOpacity(0.2)),
        itemBuilder: (context, idx) {
          final u = widget.users[idx];
          return ListTile(
            leading: Stack(
              children: [
                GestureDetector(
                  onTap: u.isPlaceholder
                      ? () {
                          showCustomSnackBar(context, translation('This is a placeholder user. They can register using this email.'));
                        }
                      : null,
                  child: Icon(_getRoleIcon(u.role), color: widget.colorScheme.primary),
                ),
                if (u.isPlaceholder)
                  RoleGate(
                    minRole: UserRole.hoca,
                    child: Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          showCustomSnackBar(context, translation('This is a placeholder user. They can register using this email.'));
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text('${u.firstName} ${u.lastName}', style: TextStyle(color: widget.colorScheme.onSurface)),
            subtitle: (widget.currentUser.role == UserRole.superuser || 
                      (widget.currentUser.role == UserRole.hoca && u.isPlaceholder))
                ? Text(u.email, style: TextStyle(color: widget.colorScheme.onSurface.withOpacity(0.7)))
                : null,
            trailing: (u.uid == widget.currentUser.uid)
                ? null
                : SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: RoleGate(
                            minRole: UserRole.hoca,
                            child: RoleDropdown(
                              key: ValueKey('dropdown_${u.uid}'),
                              user: u,
                              colorScheme: widget.colorScheme,
                              enabled: widget.currentUser.role.index >= UserRole.hoca.index || widget.currentUser.role == UserRole.superuser,
                            ),
                          ),
                        ),
                        RoleGate(
                          minRole: UserRole.hoca,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: widget.colorScheme.onSurface),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                // open edit name dialog
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => EditNameDialog(user: u, colorScheme: widget.colorScheme),
                                );
                              } else if (val == 'delete') {
                                final confirmed = await showDeleteDialog(context: context, thingToDelete: translation(context: context, 'placeholder user'));
                                if (confirmed != true) return;
                                try {
                                  await FirebaseFirestore.instance.collection('user_list').doc(u.uid).delete();
                                  // record write
                                  try { ProviderScope.containerOf(context).read(firestoreQuotaProvider).recordWrite(); } catch (_) {}
                                  if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Placeholder user deleted.'));
                                } catch (e) {
                                  if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Failed to delete user: ') + e.toString());
                                }
                              } else if (val == 'migrate') {
                                // open migrate dialog (pass operator)
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => MigrateDialog(user: u, operator: widget.currentUser),
                                );
                              } else if (val == 'change_place') {
                                // open change place dialog defined in users_page.dart
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => ChangePlaceDialog(user: u),
                                );
                              }
                            },
                            itemBuilder: (ctx) {
                              final items = <PopupMenuEntry<String>>[
                                PopupMenuItem(value: 'edit', child: Text(translation(context: context, 'Edit Name'))),
                                PopupMenuItem(value: 'change_place', child: Text(translation(context: context, 'Change Place'))),
                              ];
                              if (u.isPlaceholder) {
                                items.add(PopupMenuItem(value: 'delete', child: Text(translation(context: context, 'Delete Placeholder'))));
                              } else {
                                // non-placeholder users can migrate to an existing placeholder
                                items.add(PopupMenuItem(value: 'migrate', child: Text(translation(context: context, 'Migrate'))));
                              }
                              return items;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
          );
        },
      ),
    );
  }
}

// Dialog to migrate a real user into an existing placeholder user (merge)
class MigrateDialog extends StatefulWidget {
  final UserEntity user;
  final UserEntity operator;
  const MigrateDialog({super.key, required this.user, required this.operator});

  @override
  State<MigrateDialog> createState() => _MigrateDialogState();
}

class _MigrateDialogState extends State<MigrateDialog> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _placeholders = [];
  String? _selectedPlaceholderId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPlaceholders();
  }

  Future<void> _loadPlaceholders() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user_list')
          .where('placeId', isEqualTo: widget.user.placeId)
          .where('isPlaceholder', isEqualTo: true)
          .get();
      setState(() {
        _placeholders = snap.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
        if (_placeholders.isNotEmpty) _selectedPlaceholderId = _placeholders.first.id;
      });
      try { ProviderScope.containerOf(context).read(firestoreQuotaProvider).recordRead(); } catch (_) {}
    } catch (e) {
      if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Failed to load placeholders: ') + e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmMigrate() async {
    if (_selectedPlaceholderId == null) return;
    // explicit confirmation because migration deletes the placeholder
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translation(context: context, 'Confirm Migration')),
        content: Text(translation(context: context, 'This action is irreversible. The placeholder user will be deleted and the selected user will be updated. Are you sure you want to continue?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(translation(context: context, 'Confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      final placeholderDoc = await FirebaseFirestore.instance.collection('user_list').doc(_selectedPlaceholderId!).get();
      final placeholderData = placeholderDoc.data() ?? {};

      // Update existing user doc with placeholder data
      await FirebaseFirestore.instance.collection('user_list').doc(widget.user.uid).update({
        'firstName': placeholderData['firstName'] ?? widget.user.firstName,
        'lastName': placeholderData['lastName'] ?? widget.user.lastName,
        'role': placeholderData['role'] ?? widget.user.role.name,
        'placeId': placeholderData['placeId'] ?? widget.user.placeId,
        'linkedFromPlaceholder': true,
        'originalPlaceholderId': placeholderDoc.id,
        'linkedAt': FieldValue.serverTimestamp(),
        'linkedBy': widget.operator.uid,
      });
      try { ProviderScope.containerOf(context).read(firestoreQuotaProvider).recordWrite(); } catch (_) {}

      // Delete placeholder
      await FirebaseFirestore.instance.collection('user_list').doc(placeholderDoc.id).delete();
      try { ProviderScope.containerOf(context).read(firestoreQuotaProvider).recordWrite(); } catch (_) {}

      if (context.mounted) {
        Navigator.of(context).pop();
        showCustomSnackBar(context, translation(context: context, 'User migrated successfully.'));
      }
    } catch (e) {
      if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Migration failed: ') + e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(translation(context: context, 'Migrate User')),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : _placeholders.isEmpty
              ? Text(translation(context: context, 'No placeholder users found in this place.'))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              translation(context: context, "This action is irreversible. The placeholder user's data will be merged into the selected user and the placeholder will be deleted. Please double-check your selection."),
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                  value: _selectedPlaceholderId,
                  items: _placeholders
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.data()['email'] ?? d.id)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPlaceholderId = v),
                  decoration: InputDecoration(labelText: translation(context: context, 'Select placeholder')),
                ),
                  ],
                ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(translation(context: context, 'Cancel'))),
        ElevatedButton(
          onPressed: (_saving || _selectedPlaceholderId == null) ? null : _confirmMigrate,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(translation(context: context, 'Migrate')),
        ),
      ],
    );
  }
}

