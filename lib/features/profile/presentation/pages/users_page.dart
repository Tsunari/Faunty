import 'package:faunty/features/profile/domain/entities/place_model.dart';
import 'package:faunty/features/profile/presentation/pages/user_list.dart';
import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/profile/presentation/controllers/place_provider.dart';
import 'package:faunty/core/utils/sort_utils.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  bool _showAllPlaces = false;
  bool _prefsLoaded = false;
  static const _prefKeyShowAll = 'users_show_all_places';

  Future<void> _loadPref() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final val = sp.getBool(_prefKeyShowAll);
      if (val != null) setState(() => _showAllPlaces = val);
    } catch (_) {}
  }

  Future<void> _toggleShowAllPlaces() async {
    setState(() => _showAllPlaces = !_showAllPlaces);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_prefKeyShowAll, _showAllPlaces);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading user: $e')),
      data: (user) {
        if (user == null) {
          return Center(child: Text(translation('No user loaded.', context: context)));
        }
        if (!_prefsLoaded && user.role == UserRole.superuser) {
          _prefsLoaded = true;
          _loadPref();
        }
        final usersByPlaceAsync = ref.watch(
          usersByCurrentPlaceProviderWithOptions(
            const UserSortOption(field: UserSortField.firstName, order: SortOrder.asc),
          ),
        );
        final placesAsync = ref.watch(placeStreamProvider);
        return Scaffold(
          appBar: CustomAppBar(
            title: translation('Users', context: context),
            actions: [
              RoleGate(
                minRole: UserRole.superuser,
                child: IconButton(
                  icon: Icon(_showAllPlaces ? Icons.view_agenda_rounded : Icons.view_column_rounded),
                  tooltip: translation(_showAllPlaces ? 'Show single place' : 'Show all places', context: context),
                  onPressed: () => _toggleShowAllPlaces(),
                ),
              ),
              RoleGate(
                minRole: UserRole.baskan,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showCreateUserDialog(context, user),
                    tooltip: translation('Create User', context: context),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.surface,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _showAllPlaces
              ? placesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(translation('Error loading places: ', context: context) + e.toString())),
                  data: (places) {
                    if (places.isEmpty) return Center(child: Text(translation('No places available.', context: context)));
                    return DefaultTabController(
                      length: places.length,
                      child: Column(
                        children: [
                          Material(
                            color: colorScheme.surface,
                            child: TabBar(
                              isScrollable: true,
                              tabs: places.map((p) => Tab(text: p.displayName ?? p.name)).toList(),
                              tabAlignment: TabAlignment.center,
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: places.map((place) {
                                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('user_list')
                                      .where('placeId', isEqualTo: place.id)
                                      .snapshots(),
                                  builder: (ctx, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                    if (snap.hasError) return Center(child: Text(translation('Failed to load users: ', context: context) + snap.error.toString()));
                                    final docs = snap.data?.docs ?? [];
                                    final users = docs.map((d) => UserEntity.fromMap(d.data())).toList();
                                    users.sort((a, b) => compareUsersByOption(a, b, const UserSortOption(field: UserSortField.firstName, order: SortOrder.asc)));
                                    return _buildUsersForPlace(users, colorScheme, user);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : usersByPlaceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error loading users: $e')),
                  data: (users) => _buildUsersForPlace(users, colorScheme, user),
                ),
            ),
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

  Widget _buildUsersForPlace(List<UserEntity> users, ColorScheme colorScheme, UserEntity currentUser) {
    final Map<UserRole, List<UserEntity>> grouped = {};
    for (final u in users) {
      grouped.putIfAbsent(u.role, () => []).add(u);
    }
    final sortedRoles = UserRole.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        for (final role in sortedRoles)
          if (grouped[role]?.isNotEmpty ?? false)
            if ((role != UserRole.superuser || currentUser.role == UserRole.superuser) &&
                ((role != UserRole.user && role != UserRole.spectator && role != UserRole.archived && role != UserRole.unknown) || currentUser.role.index <= UserRole.hoca.index) ||
                (role == UserRole.spectator && currentUser.role == UserRole.spectator))
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '${translation(role.name, context: context).toUpperCase()} (${grouped[role]!.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        UserListWithScrollbar(
                          users: grouped[role]!,
                          colorScheme: colorScheme,
                          currentUser: currentUser,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _loading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: _selectedRole,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                dropdownColor: colorScheme.surfaceContainerHigh,
                alignment: Alignment.center,
                items: UserRole.values
                    .where((r) => r != UserRole.superuser)
                    .map((role) => DropdownMenuItem<UserRole>(
                          value: role,
                          alignment: Alignment.center,
                          child: Text(
                            translation(role.name, context: context),
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
                            showCustomSnackBar(context, translation('Failed to update role: ', context: context) + e.toString());
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      }
                    : null,
              ),
            ),
          );
  }
}

class EditNameDialog extends StatefulWidget {
  final UserEntity user;
  final ColorScheme colorScheme;
  const EditNameDialog({super.key, required this.user, required this.colorScheme});

  @override
  State<EditNameDialog> createState() => EditNameDialogState();
}

class EditNameDialogState extends State<EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: widget.colorScheme.primary),
            const SizedBox(width: 10),
            Text(translation('Edit Name', context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: translation('First Name', context: context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return translation('Please enter first name', context: context);
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: translation('Last Name', context: context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return translation('Please enter last name', context: context);
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(translation('Cancel', context: context)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colorScheme.primary,
            foregroundColor: widget.colorScheme.onPrimary,
          ),
          onPressed: _loading
              ? null
              : () async {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  setState(() => _loading = true);
                  final newFirst = _firstNameController.text.trim();
                  final newLast = _lastNameController.text.trim();
                  try {
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
                      showCustomSnackBar(context, translation('Failed to update name: ', context: context) + e.toString());
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
              : Text(translation('Save', context: context)),
        ),
      ],
    );
  }
}

class CreateUserDialog extends StatefulWidget {
  final UserEntity currentUser;
  const CreateUserDialog({super.key, required this.currentUser});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class ChangePlaceDialog extends ConsumerStatefulWidget {
  final UserEntity user;
  const ChangePlaceDialog({super.key, required this.user});

  @override
  ConsumerState<ChangePlaceDialog> createState() => _ChangePlaceDialogState();
}

class _ChangePlaceDialogState extends ConsumerState<ChangePlaceDialog> {
  String? _selectedPlaceId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlaceId = widget.user.placeId;
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placeStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(translation('Change Place', context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: placesAsync.when(
        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => Text(translation('Failed to load places: ', context: context) + e.toString()),
        data: (places) {
          return DropdownButtonFormField<String>(
            value: _selectedPlaceId,
            items: places.map((p) => DropdownMenuItem(value: p.id, child: Text(p.displayName ?? p.name))).toList(),
            onChanged: (v) => setState(() => _selectedPlaceId = v),
            decoration: InputDecoration(
              labelText: translation('Place', context: context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: Text(translation('Cancel', context: context))),
        ElevatedButton(
          onPressed: (_loading || _selectedPlaceId == null || _selectedPlaceId == widget.user.placeId)
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await FirebaseFirestore.instance.collection('user_list').doc(widget.user.uid).update({'placeId': _selectedPlaceId});
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) showCustomSnackBar(context, translation('Failed to change place: ', context: context) + e.toString());
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(translation('Save', context: context)),
        ),
      ],
    );
  }
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  UserRole _selectedRole = UserRole.talebe;
  bool _loading = false;
  final bool _autoEmail = true;

  @override
  void dispose() {
    _firstNameController.removeListener(_updateEmail);
    _lastNameController.removeListener(_updateEmail);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateEmail);
    _lastNameController.addListener(_updateEmail);
    _updateEmail();
  }

  void _updateEmail() {
    if (!_autoEmail) return;
    final f = _sanitize(_firstNameController.text);
    final l = _sanitize(_lastNameController.text);
    final generated = (f.isEmpty && l.isEmpty) ? '' : '${f.isEmpty ? 'user' : f}@${l.isEmpty ? 'example' : l}.com';
    if (_emailController.text != generated) {
      _emailController.text = generated;
    }
  }

  String _sanitize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final tempUid = 'ph_${const Uuid().v4()}';

      await FirebaseFirestore.instance.collection('user_list').doc(tempUid).set({
        'uid': tempUid,
        'email': email,
        'placeId': widget.currentUser.placeId,
        'firstName': firstName,
        'lastName': lastName,
        'role': _selectedRole.name,
        'isPlaceholder': true,
        'createdBy': widget.currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        showCustomSnackBar(context, translation('User created successfully. They can now register with this email.', context: context));
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, translation('Failed to create user: ', context: context) + e.toString());
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(translation('Create New User', context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: translation('First Name', context: context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation('Please enter first name', context: context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: translation('Last Name', context: context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation('Please enter last name', context: context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: translation('Email', context: context),
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translation('Please enter an email', context: context);
                  }
                  if (!value.contains('@')) {
                    return translation('Please enter a valid email', context: context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: translation('Role', context: context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: UserRole.values
                    .where((role) => role != UserRole.superuser)
                    .map((role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(translation(role.name, context: context)),
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Text(
                  translation('Note: The user will be created as a placeholder. They can register using this email address (does not have to exist necessarily), and their account will be linked automatically.', context: context),
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
          child: Text(translation('Cancel', context: context)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _createUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(translation('Create User', context: context)),
        ),
      ],
    );
  }
}