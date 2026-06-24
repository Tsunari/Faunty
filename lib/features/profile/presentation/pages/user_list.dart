import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_confirm_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/profile/presentation/pages/users_page.dart';

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

  IconData _getRoleIcon(UserRole role, bool isPlaceholder) {
    switch (role) {
      case UserRole.superuser:
        return Icons.admin_panel_settings_rounded;
      case UserRole.hoca:
        return Icons.school_rounded;
      case UserRole.baskan:
      case UserRole.talebe:
        return isPlaceholder ? Icons.person_outline_rounded : Icons.how_to_reg_rounded;
      case UserRole.user:
        return Icons.person_add_alt_rounded;
      case UserRole.spectator:
        return Icons.visibility_rounded;
      case UserRole.archived:
        return Icons.archive_rounded;
      case UserRole.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.users.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        separatorBuilder: (_, __) => Divider(height: 1, color: widget.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        itemBuilder: (context, idx) {
          final u = widget.users[idx];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: GestureDetector(
              onTap: u.isPlaceholder
                  ? () {
                      showCustomSnackBar(context, translation('This is a placeholder user. They can register using this email.', context: context));
                    }
                  : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: u.isPlaceholder 
                        ? widget.colorScheme.surfaceContainerHighest
                        : widget.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    child: Icon(
                      _getRoleIcon(u.role, u.isPlaceholder),
                      color: u.isPlaceholder ? widget.colorScheme.onSurfaceVariant : widget.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  if (u.isPlaceholder)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${u.firstName} ${u.lastName}',
                    style: TextStyle(
                      color: widget.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (u.isPlaceholder) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Text(
                      translation('Pending', context: context).toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ]
              ],
            ),
            subtitle: (widget.currentUser.role == UserRole.superuser || 
                      (widget.currentUser.role == UserRole.hoca && u.isPlaceholder))
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 12, color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            u.email,
                            style: TextStyle(
                              color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            trailing: (u.uid == widget.currentUser.uid)
                ? null
                : SizedBox(
                    width: 170,
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
                            icon: Icon(Icons.more_vert_rounded, color: widget.colorScheme.onSurfaceVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => EditNameDialog(user: u, colorScheme: widget.colorScheme),
                                );
                              } else if (val == 'delete') {
                                final confirmed = await showDeleteDialog(context: context, thingToDelete: translation('placeholder user', context: context));
                                if (confirmed != true) return;
                                try {
                                  await FirebaseFirestore.instance.collection('user_list').doc(u.uid).delete();
                                  if (context.mounted) showCustomSnackBar(context, translation('Placeholder user deleted.', context: context));
                                } catch (e) {
                                  if (context.mounted) showCustomSnackBar(context, translation('Failed to delete user: ', context: context) + e.toString());
                                }
                              } else if (val == 'migrate') {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => MigrateDialog(user: u, operator: widget.currentUser),
                                );
                              } else if (val == 'change_place') {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => ChangePlaceDialog(user: u),
                                );
                              }
                            },
                            itemBuilder: (ctx) {
                              final items = <PopupMenuEntry<String>>[
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(translation('Edit Name', context: context)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'change_place',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.place_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(translation('Change Place', context: context)),
                                    ],
                                  ),
                                ),
                              ];
                              if (u.isPlaceholder) {
                                items.add(
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
                                        const SizedBox(width: 8),
                                        Text(
                                          translation('Delete Placeholder', context: context),
                                          style: TextStyle(color: theme.colorScheme.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                items.add(
                                  PopupMenuItem(
                                    value: 'migrate',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.merge_type_rounded, size: 18),
                                        const SizedBox(width: 8),
                                        Text(translation('Migrate', context: context)),
                                      ],
                                    ),
                                  ),
                                );
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
    } catch (e) {
      if (mounted) showCustomSnackBar(context, translation('Failed to load placeholders: ', context: context) + e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmMigrate() async {
    if (_selectedPlaceholderId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  translation('Confirm Migration', context: ctx),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: Text(
            translation(
              'This action is irreversible. The selected placeholder will be converted into the canonical user record: its email will be replaced with the migrating user\'s email, the placeholder flag will be cleared, and the existing auth-backed user document (the one with the auth UID) will be deleted. Do you want to continue?',
              context: ctx,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(translation('Cancel', context: ctx)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(translation('Confirm', context: ctx)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      final placeholderDoc = await FirebaseFirestore.instance.collection('user_list').doc(_selectedPlaceholderId!).get();
      final placeholderData = placeholderDoc.data() ?? {};

      final placeholderRef = FirebaseFirestore.instance.collection('user_list').doc(placeholderDoc.id);
      await placeholderRef.update({
        'authUid': widget.user.uid,
        'isPlaceholder': false,
        'email': widget.user.email,
        'firstName': placeholderData['firstName'] ?? widget.user.firstName,
        'lastName': placeholderData['lastName'] ?? widget.user.lastName,
        'role': placeholderData['role'] ?? widget.user.role.name,
        'placeId': placeholderData['placeId'] ?? widget.user.placeId,
        'linkedFromPlaceholder': true,
        'originalPlaceholderId': placeholderDoc.id,
        'linkedAt': FieldValue.serverTimestamp(),
        'linkedBy': widget.operator.uid,
      });

      await FirebaseFirestore.instance.collection('user_list').doc(widget.user.uid).delete();

      if (mounted) {
        Navigator.of(context).pop();
        showCustomSnackBar(context, translation('User migrated successfully.', context: context));
      }
    } catch (e) {
      if (mounted) showCustomSnackBar(context, translation('Migration failed: ', context: context) + e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.merge_type_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              translation('Migrate User', context: context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : _placeholders.isEmpty
              ? Text(translation('No placeholder users found in this place.', context: context))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              translation("This action is irreversible. The placeholder user's data will be merged into the selected user and the placeholder will be deleted. Please double-check your selection.", context: context),
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPlaceholderId,
                      items: _placeholders
                          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.data()['email'] ?? d.id)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPlaceholderId = v),
                      decoration: InputDecoration(
                        labelText: translation('Select placeholder', context: context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(translation('Cancel', context: context))),
        ElevatedButton(
          onPressed: (_saving || _selectedPlaceholderId == null) ? null : _confirmMigrate,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(translation('Migrate', context: context)),
        ),
      ],
    );
  }
}
