import 'package:faunty/pages/more/user_list.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/user_list_provider.dart';
import '../../state_management/user_provider.dart';
import '../../models/user_entity.dart';
import '../../models/user_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading user: $e')),
      data: (user) {
        if (user == null) {
          return Center(child: Text(translation(context: context, 'No user loaded.')));
        }
        final usersByPlaceAsync = ref.watch(usersByCurrentPlaceProvider);
        return Scaffold(
          appBar: AppBar(
            title: Text(translation(context: context, 'Users')),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0.5,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
          ),
          backgroundColor: colorScheme.surface,
          body: usersByPlaceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading users: $e')),
              data: (users) {
              // Group users by role
              final Map<UserRole, List<UserEntity>> grouped = {};
              for (final u in users) {
                grouped.putIfAbsent(u.role, () => []).add(u);
              }
              // Sort roles by privilege
              final sortedRoles = UserRole.values.toList()
                ..sort((a, b) => a.index.compareTo(b.index));
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final role in sortedRoles)
                    if (grouped[role]?.isNotEmpty ?? false)
                      if ((role != UserRole.superuser || user.role == UserRole.superuser) &&
                          (role != UserRole.user || user.role.index <= UserRole.hoca.index))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                role.name[0].toUpperCase() + role.name.substring(1),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            Card(
                              color: colorScheme.surface,
                              child: UserListWithScrollbar(
                                users: grouped[role]!,
                                colorScheme: colorScheme,
                                currentUser: user,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}


// Dropdown widget for changing user role
class RoleDropdown extends StatefulWidget {
  final UserEntity user;
  final ColorScheme colorScheme;
  final bool enabled;
  const RoleDropdown({super.key, required this.user, required this.colorScheme, this.enabled = true});

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  late UserRole _selectedRole;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: widget.colorScheme.secondary),
          )
        : DropdownButton<UserRole>(
            value: _selectedRole,
            isExpanded: true,
            underline: Container(height: 0),
            icon: Icon(Icons.arrow_drop_down, color: widget.colorScheme.secondary),
            style: TextStyle(color: widget.colorScheme.secondary, fontWeight: FontWeight.bold),
            dropdownColor: widget.colorScheme.surface,
            alignment: Alignment.center,
            items: UserRole.values
                .where((r) => r != UserRole.superuser)
                .map((role) => DropdownMenuItem<UserRole>(
                      value: role,
                      alignment: Alignment.center,
                      child: Text(
                        role.name[0].toUpperCase() + role.name.substring(1),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
            onChanged: widget.enabled
                ? (newRole) async {
                    if (newRole == null || newRole == _selectedRole) return;
                    setState(() => _loading = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('user_list')
                          .doc(widget.user.uid)
                          .update({'role': newRole.name});
                      setState(() => _selectedRole = newRole);
                    } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update role: $e')),
                          );
                        }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  }
                : null,
          );
  }
}

// Dialog for editing first and last name
class _EditNameDialog extends StatefulWidget {
  final UserEntity user;
  final ColorScheme colorScheme;
  const _EditNameDialog({required this.user, required this.colorScheme});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(translation(context: context, 'Edit Name')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: translation(context: context, 'First Name')),
          ),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: translation(context: context, 'Last Name')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(translation(context: context, 'Cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colorScheme.primary,
            foregroundColor: widget.colorScheme.onPrimary,
          ),
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final newFirst = _firstNameController.text.trim();
                  final newLast = _lastNameController.text.trim();
                  try {
                    // Update user name
                    await FirebaseFirestore.instance
                        .collection('user_list')
                        .doc(widget.user.uid)
                        .update({
                      'firstName': newFirst,
                      'lastName': newLast,
                    });
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(translation(context: context, 'Failed to update name: ') + e.toString())),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
