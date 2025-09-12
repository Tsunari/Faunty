import 'package:faunty/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../state_management/user_provider.dart';
import '../../state_management/place_provider.dart';
import '../../models/place_model.dart';
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
            _buildHeader(context, userAsync),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: placesAsync.when(
                data: (places) => _buildPlacesList(context, places),
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

  Widget _buildHeader(BuildContext context, AsyncValue<UserEntity?> userAsync) {
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
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
                radius: 28,
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
                    Text('${translation(context: context, 'Place')}: ${user.placeId}', style: Theme.of(context).textTheme.bodySmall),
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

  Widget _buildPlacesList(BuildContext context, List<PlaceModel> places) {
    if (places.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(translation(context: context, 'No places available.')),
      ));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: places.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final p = places[idx];
        return ListTile(
          leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(p.imageUrl!))
              : const CircleAvatar(child: Icon(Icons.place)),
          title: Text(p.displayName ?? p.name),
          subtitle: p.description != null ? Text(p.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: p.registrationMode ? Icon(Icons.how_to_reg, color: Theme.of(context).colorScheme.primary) : null,
          onTap: () => _showPlaceDetail(context, p),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showPlaceDetail(BuildContext context, PlaceModel place) {
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
