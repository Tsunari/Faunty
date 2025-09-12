import 'package:faunty/components/custom_snackbar.dart';
import 'package:faunty/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../state_management/user_provider.dart';
import '../../state_management/place_provider.dart';
import '../../models/place_model.dart';
import '../../firestore/place_firestore_service.dart';
import '../../components/role_gate.dart';
import '../../models/user_roles.dart';
import '../../firestore/user_firestore_service.dart';
import '../../models/user_entity.dart';
import '../../tools/translation_helper.dart';

/// A modern drawer used on the Home page.
/// Shows basic user info and a list of places that open a modern popout when tapped.
class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final placesAsync = ref.watch(placeStreamProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // We attempt to resolve the user's place displayName from the places stream when available
            placesAsync.when(
              data: (places) => _buildHeader(context, userAsync, places: places),
              loading: () => _buildHeader(context, userAsync),
              error: (_, __) => _buildHeader(context, userAsync),
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: placesAsync.when(
                data: (places) => Column(
                  children: [
                    Expanded(child: _buildPlacesList(context, places, ref)),
                    _buildAdminControls(context),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(translation(context: context, 'Error loading places: $e')),
                )),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(child: Text(translation(context: context, 'App version'))),
                  // You can replace this with a dynamic version value if desired
                  FutureBuilder<PackageInfo>(
                    future: getAppInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading version...');
                      }
                      if (snapshot.hasError) {
                        return Text('Version unavailable');
                      }
                      final info = snapshot.data;
                      return Text('${info?.version ?? '-'}');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<UserEntity?> userAsync, {List<PlaceModel>? places}) {
    // resolve displayName for user's current place if possible
    String resolvePlaceDisplay(UserEntity? user) {
      if (user == null) return '';
      if (places == null) return user.placeId;
      final found = PlaceModel.findById(places, user.placeId);
      return found?.displayName ?? found?.name ?? user.placeId;
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: Text(translation(context: context, 'Not signed in'))),
              ],
            ),
          );
        }

        final fullName = '${user.firstName} ${user.lastName}'.trim();
        final initials = _initials(fullName);

        return Container(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName.isEmpty ? user.email : fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('${translation(context: context, 'Role')}: ${user.role.name}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text('${translation(context: context, 'Place')}: ${resolvePlaceDisplay(user)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: const [CircularProgressIndicator(), SizedBox(width: 12), Text('Loading user...')]),
      ),
      error: (e, st) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(translation(context: context, 'Error loading user: $e')),
      ),
    );
  }

  Widget _buildPlacesList(BuildContext context, List<PlaceModel> places, WidgetRef ref) {
    if (places.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(translation(context: context, 'No places available.')),
      ));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final p = places[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
                ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(p.imageUrl!))
                : const CircleAvatar(radius: 18, child: Icon(Icons.place, size: 18)),
            title: Text(p.displayName ?? p.name),
            subtitle: p.description != null ? Text(p.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.registrationMode) Icon(Icons.how_to_reg, color: Theme.of(context).colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                RoleGate(
                  minRole: UserRole.superuser,
                  child: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'rename') {
                        await _showRenameDialog(context, p);
                      } else if (action == 'delete') {
                        await _confirmAndDelete(context, p.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showPlaceDetail(context, p, ref),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context, PlaceModel place) async {
    final controller = TextEditingController(text: place.displayName ?? place.name);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translation(context: context, 'Rename place')),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: translation(context: context, 'Place name'))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: Text(translation(context: context, 'Save'))),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await PlaceFirestoreService.updatePlace(place.id, {'displayName': result, 'name': result});
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error renaming place: $e')));
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, String placeId) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translation(context: context, 'Delete place?')),
        content: Text(translation(context: context, 'Are you sure you want to delete this place? This action cannot be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: Text(translation(context: context, 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PlaceFirestoreService.deletePlace(placeId);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting place: $e')));
    }
  }

  /// Admin controls to add a new place - only visible to superuser
  Widget _buildAdminControls(BuildContext context) {
    final nameController = TextEditingController();
    return RoleGate(
      minRole: UserRole.superuser,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(translation(context: context, 'Manage places'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: translation(context: context, 'New place name'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final newPlace = PlaceModel(id: '', name: name, displayName: name);
                  try {
                    await PlaceFirestoreService.addPlace(newPlace);
                    nameController.clear();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context: context, 'Place added'))));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding place: $e')));
                  }
                }, icon: const Icon(Icons.add), label: Text(translation(context: context, 'Add place')))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showPlaceDetail(BuildContext context, PlaceModel place, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(place.displayName ?? place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(place.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                      ),
                    if (place.imageUrl != null && place.imageUrl!.isNotEmpty) const SizedBox(height: 12),
                    if (place.description != null && place.description!.isNotEmpty)
                      Text(place.description!, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Chip(label: Text('${translation(context: context, 'ID')}: ${place.id}')),
                        const SizedBox(width: 8),
                        if (place.registrationMode) Chip(label: Text(translation(context: context, 'Registration mode'))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Action buttons placeholder
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Close and navigate to place page (optional)
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: Text(translation(context: context, 'Open')),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(translation(context: context, 'Close')),
                        ),
                        const SizedBox(width: 12),
                        // Superuser action: change current user's place to this place
                        RoleGate(
                          minRole: UserRole.superuser,
                          child: ElevatedButton.icon(
                            // style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                            onPressed: () async {
                              final confirm = await showDialog<bool?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(translation(context: context, 'Change user place')),
                                  content: Text(translation(context: context, 'Do you want to set your current place to "${place.displayName ?? place.name}"?')),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(translation(context: context, 'Cancel'))),
                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(translation(context: context, 'Yes'))),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              // get current user
                              final userAsync = ref.read(userProvider);
                              final currentUser = userAsync.asData?.value;
                              if (currentUser == null) {
                                if (context.mounted) showCustomSnackBar(context, translation(context: context, 'No current user loaded'));
                                return;
                              }
                              final updated = UserEntity(
                                uid: currentUser.uid,
                                email: currentUser.email,
                                firstName: currentUser.firstName,
                                lastName: currentUser.lastName,
                                role: currentUser.role,
                                placeId: place.id,
                                isPlaceholder: currentUser.isPlaceholder,
                              );
                              try {
                                await UserFirestoreService().updateUser(updated);
                                if (context.mounted) {
                                  showCustomSnackBar(context, translation(context: context, 'Place updated'));
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Error updating place: $e'));
                              }
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: Text(translation(context: context, 'Set as my place')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
