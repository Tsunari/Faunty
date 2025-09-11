import 'package:faunty/pages/more/user_list.dart';
import 'package:faunty/components/role_gate.dart';
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
            actions: [
              RoleGate(
                minRole: UserRole.hoca,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showCreateUserDialog(context, user),
                    tooltip: translation(context: context, 'Create User'),
                  ),
                ),
              ),
            ],
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
                                '${role.name[0].toUpperCase() + role.name.substring(1)} (${grouped[role]!.length})',
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

  void _showCreateUserDialog(BuildContext context, UserEntity currentUser) {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(currentUser: currentUser),
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
  void didUpdateWidget(RoleDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid || oldWidget.user.role != widget.user.role) {
      _selectedRole = widget.user.role;
    }
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

// Dialog for creating new users
class CreateUserDialog extends StatefulWidget {
  final UserEntity currentUser;

  const CreateUserDialog({super.key, required this.currentUser});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      // Generate a temporary UID for the placeholder user
      final tempUid = 'temp_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode.abs()}';

      // Create placeholder user in Firestore
      await FirebaseFirestore.instance.collection('user_list').doc(tempUid).set({
        'uid': tempUid,
        'email': email,
        'placeId': widget.currentUser.placeId,
        'firstName': firstName,
        'lastName': lastName,
        'role': _selectedRole.name,
        'isPlaceholder': true, // Mark as placeholder user
        'createdBy': widget.currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context: context, 'User created successfully. They can now register with this email.')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context: context, 'Failed to create user: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(translation(context: context, 'Create New User')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Email'),
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation(context: context, 'Please enter an email');
                  }
                  if (!value.contains('@')) {
                    return translation(context: context, 'Please enter a valid email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'First Name'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation(context: context, 'Please enter first name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Last Name'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation(context: context, 'Please enter last name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Role'),
                ),
                items: UserRole.values
                    .where((role) => role != UserRole.superuser) // Don't allow creating superusers
                    .map((role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.name[0].toUpperCase() + role.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  translation(context: context, 'Note: The user will be created as a placeholder. They can register using this email address (does not have to exist necessarily), and their account will be linked automatically.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(translation(context: context, 'Cancel')),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _createUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(translation(context: context, 'Create User')),
        ),
      ],
    );
  }
}
