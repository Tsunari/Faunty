import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/presentation/pages/cleaning_assign.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/core/widgets/custom_chip.dart';
import 'package:faunty/features/lists/presentation/controllers/cleaning_provider.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';

class CleaningPage extends ConsumerStatefulWidget {
  const CleaningPage({super.key});

  @override
  ConsumerState<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends ConsumerState<CleaningPage> {
  bool _reorderMode = false;

  Future<void> _movePlace(Map<String, dynamic> data, String placeId, int direction, WidgetRef ref) async {
    final placesMap = Map<String, dynamic>.from(data['places'] as Map? ?? {});
    final place = placesMap[placeId] as Map<String, dynamic>?;
    if (place == null) return;
    final groupId = (place['group'] as String?) ?? '';
    final siblings = placesMap.entries.where((e) {
      final g = (e.value as Map<String, dynamic>)['group'] as String?;
      return (g ?? '') == groupId;
    }).map((e) => e.key).toList();
    siblings.sort((a, b) {
      final pa = placesMap[a] as Map<String, dynamic>;
      final pb = placesMap[b] as Map<String, dynamic>;
      final posa = pa['pos'] is int ? pa['pos'] as int : 0;
      final posb = pb['pos'] is int ? pb['pos'] as int : 0;
      return posa.compareTo(posb);
    });
    final currentIndex = siblings.indexOf(placeId);
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= siblings.length) return;
    final otherId = siblings[targetIndex];
    final pa = Map<String, dynamic>.from(placesMap[placeId] as Map<String, dynamic>);
    final pb = Map<String, dynamic>.from(placesMap[otherId] as Map<String, dynamic>);
    final posa = pa['pos'] is int ? pa['pos'] as int : 0;
    final posb = pb['pos'] is int ? pb['pos'] as int : 0;
    pa['pos'] = posb;
    pb['pos'] = posa;
    placesMap[placeId] = pa;
    placesMap[otherId] = pb;
    final service = ref.read(cleaningFirestoreServiceProvider);
    await service.setCleaning(placesMap);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final cleaningDataAsync = ref.watch(cleaningDataProvider);
    // Resolve users for the current place to map UIDs to names
    final usersAsync = ref.watch(usersByCurrentPlaceProvider);
    final usersForPlace = usersAsync.asData?.value ?? <UserEntity>[];
    final userRole = ref.watch(userProvider).maybeWhen(data: (u) => u?.role, orElse: () => null);
    final canReorder = userRole != null && userRole.index <= UserRole.baskan.index;

    String formatAssigneeLabel(String entry) {
      // Accepted formats:
      // - "uid_first_last" (legacy)
      // - "uid first last" (some data entries)
      // - "uid" only (fallback)
      // - Placeholder: "ph_uid_first_last" or "ph uid first last" -> skip 'ph' prefix
      // Prefer resolving real name by UID from users provider.
      final tokens = entry.split(RegExp(r'[ _]')).where((t) => t.isNotEmpty).toList();
      if (tokens.isEmpty) return entry;
      // If placeholder prefix present, UID is the second token
      final hasPhPrefix = tokens.first.toLowerCase() == 'ph';
      final uidToken = hasPhPrefix && tokens.length >= 2 ? tokens[1] : tokens[0];

      final matching = usersForPlace.where((u) => u.uid == uidToken);
      if (matching.isNotEmpty) {
        final u = matching.first;
        final full = '${u.firstName} ${u.lastName}'.trim();
        if (full.isNotEmpty) return full;
      }
      // Fallbacks based on embedded name in the entry
      final underscore = entry.split('_');
      if (underscore.isNotEmpty) {
        final hasPh = underscore.first.toLowerCase() == 'ph';
        final nameStart = hasPh ? 2 : 1;
        if (underscore.length >= nameStart + 2) {
          return '${underscore[nameStart]} ${underscore[nameStart + 1]}';
        }
      }
      final space = entry.split(' ');
      if (space.isNotEmpty) {
        final hasPh = space.first.toLowerCase() == 'ph';
        final nameStart = hasPh ? 2 : 1;
        if (space.length >= nameStart + 2) {
          return '${space[nameStart]} ${space[nameStart + 1]}';
        }
      }
      return entry; // ultimate fallback
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Cleaning'),
        actions: [
          if (canReorder)
            IconButton(
              icon: Icon(_reorderMode ? Icons.check : Icons.swap_vert),
              tooltip: translation(context: context, _reorderMode ? 'Finish Reorder' : 'Reorder'),
              onPressed: () => setState(() => _reorderMode = !_reorderMode),
            ),
        ],
        onGeneratePdf: () async {
          final Map<String, List<Map<String, dynamic>>> pdfData = {};
          final placesMap = (cleaningDataAsync.value?['places'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          for (var entry in placesMap.entries) {
            final placeName = entry.value['name'] ?? entry.key;
            final assignees = (entry.value['assignees'] as List?)?.cast<String>() ?? [];
            if (assignees.isNotEmpty) {
              pdfData['Cleaning Assignments'] ??= [];
              pdfData['Cleaning Assignments']!.add({
                'Place': placeName,
                'Assignees': assignees.map(formatAssigneeLabel).join(', '),
              });
            }
          }
          return pdfData;
        },
        // actions: [],
      ),
      body: cleaningDataAsync.when(
        data: (data) {
          final placesMap = (data['places'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final groups = (data['groups'] as Map<String, dynamic>?) ?? {};
          final groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
          final placesNoUser = ref.watch(placesEmptyProvider);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: (placesMap.isEmpty || placesNoUser)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.cleaning_services_rounded, size: 56, color: notFoundIconColor(context)),
                          const SizedBox(height: 16),
                          Text(
                            placesNoUser && placesMap.isEmpty
                                ? translation(context: context, 'No cleaning places yet!')
                                : translation(context: context, 'No users assigned to any places.'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          RoleGate(
                            minRole: UserRole.baskan,
                            child: Text(
                              placesNoUser && placesMap.isEmpty
                                  ? translation(context: context, 'Tap below to create your first place and start assigning users.')
                                  : translation(context: context, 'Assign users to your existing places using the action button below.'),
                              style: const TextStyle(fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          placesNoUser && placesMap.isEmpty
                              ? RoleGate(
                                  minRole: UserRole.baskan,
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.add_box, color: notFoundIconColor(context)),
                                    label: Text(
                                      translation(context: context, 'Create Place'),
                                      style: TextStyle(color: notFoundIconColor(context)),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      final controller = TextEditingController();
                                      final name = await showDialog<String>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(translation(context: context, 'Create Place')),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            decoration: InputDecoration(labelText: translation(context: context, 'Place name')),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(translation(context: context, 'Cancel')),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, controller.text.trim()),
                                              child: Text(translation(context: context, 'Create')),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (name != null && name.isNotEmpty) {
                                        final service = ref.read(cleaningFirestoreServiceProvider);
                                        await service.addPlace(name);
                                      }
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      // Groups as compact expansion panels
                      ...groupOrder.map((gid) {
                        final g = groups[gid] as Map<String, dynamic>?;
                        if (g == null) return const SizedBox.shrink();
                        final title = (g['title'] ?? '').toString();
                        final plist = (g['places'] as List?)?.cast<String>() ?? [];
                        plist.sort((a, b) {
                          final pa = placesMap[a] as Map<String, dynamic>? ?? {};
                          final pb = placesMap[b] as Map<String, dynamic>? ?? {};
                          final posa = pa['pos'] is int ? pa['pos'] as int : 0;
                          final posb = pb['pos'] is int ? pb['pos'] as int : 0;
                          return posa.compareTo(posb);
                        });

                        final children = plist.map((pid) {
                          final placeData = placesMap[pid] as Map<String, dynamic>? ?? {};
                          final placeName = (placeData['name'] ?? '').toString();
                          final assigned = (placeData['assignees'] as List?)?.cast<String>() ?? [];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (canReorder && _reorderMode)
                                  Column(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 18,
                                        icon: const Icon(Icons.arrow_upward),
                                        tooltip: translation(context: context, 'Move Up'),
                                        onPressed: () => _movePlace(cleaningDataAsync.value ?? {}, pid, -1, ref),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 18,
                                        icon: const Icon(Icons.arrow_downward),
                                        tooltip: translation(context: context, 'Move Down'),
                                        onPressed: () => _movePlace(cleaningDataAsync.value ?? {}, pid, 1, ref),
                                      ),
                                    ],
                                  ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      placeName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                                    child: assigned.isNotEmpty
                                        ? Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: assigned
                                                .map((entry) => _AssigneeChip(label: formatAssigneeLabel(entry)))
                                                .toList(),
                                          )
                                        : Text(
                                            translation(context: context, 'No users assigned'),
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4), width: 1.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
                              childrenPadding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 8.0),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                  _CountChip(count: plist.length),
                                ],
                              ),
                              collapsedIconColor: Theme.of(context).colorScheme.onSurface,
                              iconColor: Theme.of(context).colorScheme.onSurface,
                              children: [
                                ...children,
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Ungrouped places (compact list)
                      Builder(builder: (context) {
                        final ungrouped = placesMap.entries.where((e) {
                          final p = e.value as Map<String, dynamic>;
                          return (p['group'] == null) || (p['group'] == '');
                        }).toList();
                        if (ungrouped.isEmpty) return const SizedBox.shrink();
                        ungrouped.sort((a, b) {
                          final pa = a.value as Map<String, dynamic>;
                          final pb = b.value as Map<String, dynamic>;
                          final posa = pa['pos'] is int ? pa['pos'] as int : 0;
                          final posb = pb['pos'] is int ? pb['pos'] as int : 0;
                          return posa.compareTo(posb);
                        });

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4), width: 1.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              children: [
                                for (int i = 0; i < ungrouped.length; i++) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (canReorder && _reorderMode)
                                          Column(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                iconSize: 18,
                                                icon: const Icon(Icons.arrow_upward),
                                                tooltip: translation(context: context, 'Move Up'),
                                                onPressed: () => _movePlace(cleaningDataAsync.value ?? {}, ungrouped[i].key, -1, ref),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                iconSize: 18,
                                                icon: const Icon(Icons.arrow_downward),
                                                tooltip: translation(context: context, 'Move Down'),
                                                onPressed: () => _movePlace(cleaningDataAsync.value ?? {}, ungrouped[i].key, 1, ref),
                                              ),
                                            ],
                                          ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Text(
                                              (ungrouped[i].value['name'] ?? '').toString(),
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                              maxLines: 2,
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                                            child: (() {
                                              final assigned = (ungrouped[i].value['assignees'] as List?)?.cast<String>() ?? [];
                                              return assigned.isNotEmpty
                                                  ? Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: assigned
                                                          .map((entry) => _AssigneeChip(label: formatAssigneeLabel(entry)))
                                                          .toList(),
                                                    )
                                                  : Text(
                                                      translation(context: context, 'No users assigned'),
                                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                    );
                                            })(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading cleaning data: $e')),
      ),
      floatingActionButton: RoleGate(
        minRole: UserRole.baskan,
        child: FloatingActionButton(
          onPressed: () async {
            final data = cleaningDataAsync.value ?? {};
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CleaningAssignPage(initialData: Map<String, dynamic>.from(data)),
              ),
            );
          },
          tooltip: translation(context: context, 'Edit'),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  final String label;
  const _AssigneeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final borderClr = dark
        ? Colors.white.withOpacity(0.18)
        : theme.colorScheme.outlineVariant.withOpacity(0.55);
    final bg = dark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.22)
        : theme.colorScheme.surfaceVariant.withOpacity(0.35);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderClr, width: 1.0),
        ),
        backgroundColor: bg,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}