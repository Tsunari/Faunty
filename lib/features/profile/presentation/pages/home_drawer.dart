import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/profile/presentation/controllers/place_provider.dart';
import 'package:faunty/features/profile/domain/entities/place_model.dart';
import 'package:faunty/features/profile/data/repositories/place_firestore_service.dart';
import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/auth/data/repositories/user_firestore_service.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:faunty/core/utils/update_service.dart';
import 'package:faunty/core/widgets/glass_container.dart';

/// A modern drawer used on the Home page.
/// Shows basic user info and a list of places that open a modern popout when tapped.
class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final placesAsync = ref.watch(placeStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildGroupCard(List<Widget> children) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 0,
        blur: 15.0,
        borderWidth: 0,
        boxShadow: const [],
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User header section
              placesAsync.when(
                data: (places) =>
                    _buildHeader(context, userAsync, places: places),
                loading: () => _buildHeader(context, userAsync),
                error: (_, __) => _buildHeader(context, userAsync),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: placesAsync.when(
                  data: (places) => SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Section title
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 12.0,
                            bottom: 4.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              translation(
                                context: context,
                                'Places',
                              ).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // List of places grouped in card
                        _buildPlacesCardList(
                          context,
                          places,
                          ref,
                          buildGroupCard,
                        ),

                        // Admin controls if applicable
                        _buildAdminControls(context, buildGroupCard),
                      ],
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        translation(
                          context: context,
                          'Error loading places: $e',
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Footer with App Version
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        translation(context: context, 'App version'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    FutureBuilder<PackageInfo>(
                      future: getAppInfo(),
                      builder: (context, snapshot) {
                        Widget label;
                        final stored = UpdateService.storedVersion;
                        if (stored != null) {
                          label = Text(
                            stored,
                            style: theme.textTheme.bodySmall,
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          label = Text(
                            translation(context: context, 'Loading...'),
                            style: theme.textTheme.bodySmall,
                          );
                        } else if (snapshot.hasError) {
                          label = Text(
                            translation(
                              context: context,
                              'Version unavailable',
                            ),
                            style: theme.textTheme.bodySmall,
                          );
                        } else {
                          final info = snapshot.data;
                          label = Text(
                            info?.version ?? '-',
                            style: theme.textTheme.bodySmall,
                          );
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            label,
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: translation(
                                context: context,
                                'Check for updates',
                              ),
                              icon: const Icon(Icons.refresh, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                UpdateService.manualCheck(
                                  forceDialog: true,
                                  showUpToDateSnack: false,
                                  promptRefreshIfUpToDate: true,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<UserEntity?> userAsync, {
    List<PlaceModel>? places,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(translation(context: context, 'Not signed in')),
                ),
              ],
            ),
          );
        }

        final fullName = '${user.firstName} ${user.lastName}'.trim();
        final initials = _initials(fullName);

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? user.email : fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${translation(context: context, 'Role')}: ${user.role.name}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${translation(context: context, 'Place')}: ${resolvePlaceDisplay(user)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(24.0),
        child: const Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(width: 16),
            Text('Loading profile...'),
          ],
        ),
      ),
      error: (e, st) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(translation(context: context, 'Error loading user: $e')),
      ),
    );
  }

  Widget _buildPlacesCardList(
    BuildContext context,
    List<PlaceModel> places,
    WidgetRef ref,
    Widget Function(List<Widget>) buildGroupCard,
  ) {
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(translation(context: context, 'No places available.')),
        ),
      );
    }

    final currentUser = ref.watch(userProvider).asData?.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listTiles = <Widget>[];

    for (int i = 0; i < places.length; i++) {
      final p = places[i];
      final isCurrentPlace = currentUser != null && currentUser.placeId == p.id;

      listTiles.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          tileColor: isCurrentPlace
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : theme.colorScheme.primary.withValues(alpha: 0.05))
              : null,
          leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(p.imageUrl!),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
          title: Text(
            p.displayName ?? p.name,
            style: TextStyle(
              fontWeight: isCurrentPlace ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPlace
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: p.description != null
              ? Text(
                  p.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrentPlace)
                Icon(
                  Icons.how_to_reg,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              const SizedBox(width: 6),
              RoleGate(
                minRole: UserRole.superuser,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 20),
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

      // Add a thin divider between elements (but not at the end)
      if (i < places.length - 1) {
        listTiles.add(const Divider(height: 1, indent: 56));
      }
    }

    return buildGroupCard(listTiles);
  }

  Future<void> _showRenameDialog(BuildContext context, PlaceModel place) async {
    final controller = TextEditingController(
      text: place.displayName ?? place.name,
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            translation(context: ctx, 'Rename place'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: translation(context: ctx, 'Place name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(translation(context: ctx, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(translation(context: ctx, 'Save')),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await PlaceFirestoreService.updatePlace(place.id, {
        'displayName': result,
        'name': result,
      });
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error renaming place: $e')));
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, String placeId) async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            translation(context: ctx, 'Delete place?'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          translation(
            context: ctx,
            'Are you sure you want to delete this place? This action cannot be undone.',
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(translation(context: ctx, 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(translation(context: ctx, 'Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PlaceFirestoreService.deletePlace(placeId);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting place: $e')));
    }
  }

  /// Admin controls to add a new place - only visible to superuser
  Widget _buildAdminControls(
    BuildContext context,
    Widget Function(List<Widget>) buildGroupCard,
  ) {
    final nameController = TextEditingController();
    final theme = Theme.of(context);

    return RoleGate(
      minRole: UserRole.superuser,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(
                translation(context: context, 'Manage places').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            buildGroupCard([
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: translation(context: context, 'New place name'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final newPlace = PlaceModel(
                      id: '',
                      name: name,
                      displayName: name,
                    );
                    try {
                      await PlaceFirestoreService.addPlace(newPlace);
                      nameController.clear();
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              translation(context: context, 'Place added'),
                            ),
                          ),
                        );
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding place: $e')),
                        );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(translation(context: context, 'Add place')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showPlaceDetail(BuildContext context, PlaceModel place, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetCtx, scrollController) {
            final theme = Theme.of(sheetCtx);
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        place.displayName ?? place.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            place.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                        const SizedBox(height: 16),
                      if (place.description != null &&
                          place.description!.isNotEmpty)
                        Text(
                          place.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Chip(
                              label: Text(
                                '${translation(context: context, 'ID')}: ${place.id}',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RoleGate(
                              minRole: UserRole.superuser,
                              fallback: Chip(
                                label: Text(
                                  '${translation(context: context, 'Registration mode')}: ${place.registrationMode ? translation(context: context, 'On') : translation(context: context, 'Off')}',
                                ),
                                backgroundColor: place.registrationMode
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      )
                                    : theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Consumer(
                                builder: (ctx, ref2, _) {
                                  final placesAsync = ref2.watch(
                                    placeStreamProvider,
                                  );
                                  final current = placesAsync.asData?.value
                                      .firstWhere(
                                        (pl) => pl.id == place.id,
                                        orElse: () => place,
                                      );
                                  final regOn =
                                      current?.registrationMode ??
                                      place.registrationMode;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      try {
                                        await PlaceFirestoreService.updatePlace(
                                          place.id,
                                          {'registrationMode': !regOn},
                                        );
                                        if (context.mounted)
                                          showCustomSnackBar(
                                            context,
                                            translation(
                                              context: context,
                                              'Registration mode updated',
                                            ),
                                          );
                                      } catch (e) {
                                        if (context.mounted)
                                          showCustomSnackBar(
                                            context,
                                            translation(
                                              context: context,
                                              'Error updating registration mode: $e',
                                            ),
                                          );
                                      }
                                    },
                                    child: Chip(
                                      label: Text(
                                        '${translation(context: context, 'Registration mode')}: ${regOn ? translation(context: context, 'On') : translation(context: context, 'Off')}',
                                      ),
                                      backgroundColor: regOn
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.12)
                                          : theme.colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons in details sheet
                      Row(
                        children: [
                          if (place.mapsUrl != null &&
                              place.mapsUrl!.isNotEmpty) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.tryParse(place.mapsUrl!);
                                  if (uri == null) {
                                    if (context.mounted)
                                      showCustomSnackBar(
                                        context,
                                        translation(
                                          context: context,
                                          'Invalid Maps URL',
                                        ),
                                      );
                                    return;
                                  }
                                  try {
                                    if (!await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    )) {
                                      if (context.mounted)
                                        showCustomSnackBar(
                                          context,
                                          translation(
                                            context: context,
                                            'Could not open URL',
                                          ),
                                        );
                                    }
                                  } catch (e) {
                                    if (context.mounted)
                                      showCustomSnackBar(
                                        context,
                                        translation(
                                          context: context,
                                          'Error opening URL: $e',
                                        ),
                                      );
                                  }
                                },
                                icon: const Icon(Icons.map, size: 18),
                                label: Text(
                                  translation(context: context, 'Open in Maps'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetCtx).pop();
                              },
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(
                                translation(context: context, 'Open'),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      RoleGate(
                        minRole: UserRole.hoca,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Center(
                                    child: Text(
                                      translation(
                                        context: ctx,
                                        'Change user place',
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  content: Text(
                                    translation(
                                      context: ctx,
                                      'Do you want to set your current place to "${place.displayName ?? place.name}"?',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(
                                        translation(context: ctx, 'Cancel'),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(
                                        translation(context: ctx, 'Yes'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;

                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                              }

                              final userAsync = ref.read(userProvider);
                              final currentUser = userAsync.asData?.value;
                              if (currentUser == null) {
                                if (context.mounted)
                                  showCustomSnackBar(
                                    context,
                                    translation(
                                      context: context,
                                      'No current user loaded',
                                    ),
                                  );
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
                                await UserFirestoreService().updateUser(
                                  updated,
                                );
                                if (context.mounted) {
                                  showCustomSnackBar(
                                    context,
                                    translation(
                                      context: context,
                                      'Place updated',
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted)
                                  showCustomSnackBar(
                                    context,
                                    translation(
                                      context: context,
                                      'Error updating place: $e',
                                    ),
                                  );
                              }
                            },
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: Text(
                              translation(context: context, 'Set as my place'),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      RoleGate(
                        minRole: UserRole.superuser,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final controller = TextEditingController(
                                text: place.mapsUrl ?? '',
                              );
                              final result = await showDialog<String?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Center(
                                    child: Text(
                                      translation(
                                        context: ctx,
                                        'Connect Google Maps',
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  content: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: translation(
                                        context: ctx,
                                        'Paste maps link here (https://...)',
                                      ),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text(
                                        translation(context: ctx, 'Cancel'),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(
                                        ctx,
                                      ).pop(controller.text.trim()),
                                      child: Text(
                                        translation(context: ctx, 'Save'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (result == null) return;
                              final trimmed = result.trim();
                              try {
                                await PlaceFirestoreService.updatePlace(
                                  place.id,
                                  {'mapsUrl': trimmed},
                                );
                                if (context.mounted)
                                  showCustomSnackBar(
                                    context,
                                    translation(
                                      context: context,
                                      'Maps link updated',
                                    ),
                                  );
                              } catch (e) {
                                if (context.mounted)
                                  showCustomSnackBar(
                                    context,
                                    translation(
                                      context: context,
                                      'Error saving Maps link: $e',
                                    ),
                                  );
                              }
                            },
                            icon: const Icon(Icons.link, size: 18),
                            label: Text(
                              translation(context: context, 'Connect place'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
