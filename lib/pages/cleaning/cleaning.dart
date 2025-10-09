import 'package:faunty/components/role_gate.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cleaning_assign.dart';
import '../../components/custom_app_bar.dart';
import '../../components/custom_chip.dart';
import '../../state_management/cleaning_provider.dart';

class CleaningPage extends ConsumerWidget {
  const CleaningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleaningDataAsync = ref.watch(cleaningDataProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Cleaning'),
        actions: [],
      ),
      body: cleaningDataAsync.when(
        data: (data) {
          // data now may contain: { 'places': {...}, 'groups': {...}, 'order': [...], 'groupOrder': [...] }
          final placesMap = (data['places'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final groups = (data['groups'] as Map<String, dynamic>?) ?? {};
          final groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
          final placesNoUser = ref.watch(placesEmptyProvider);
          print('Places empty: $placesNoUser');
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (placesMap.isNotEmpty && !placesNoUser)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(translation(context: context, 'Place'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(translation(context: context, 'Assignees'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: (placesMap.isEmpty || placesNoUser)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.cleaning_services_rounded, size: 64, color: notFoundIconColor(context)),
                                const SizedBox(height: 24),
                                Text(
                                  placesNoUser && placesMap.isEmpty 
                                  ? translation(context: context, 'No cleaning places yet!') 
                                  : translation(context: context, 'No users assigned to any places.'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                RoleGate(
                                  minRole: UserRole.baskan,
                                  child: Text(
                                    placesNoUser && placesMap.isEmpty 
                                    ? translation(context: context, 'Tap below to create your first place and start assigning users.') 
                                    : translation(context: context, 'Assign users to your existing places using the action button below.'),
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                placesNoUser && placesMap.isEmpty ? RoleGate(
                                  minRole: UserRole.baskan,
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.add_box, color: notFoundIconColor(context)),
                                    label: Text(translation(context: context, 'Create Place'), style: TextStyle(color: notFoundIconColor(context))),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                            TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context: context, 'Cancel'))),
                                            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(translation(context: context, 'Create'))),
                                          ],
                                        ),
                                      );
                                      if (name != null && name.isNotEmpty) {
                                        final service = ref.read(cleaningFirestoreServiceProvider);
                                        await service.addPlace(name);
                                      }
                                    },
                                  ),
                                ) : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            // Render grouped sections first
                            ...groupOrder.map((gid) {
                              final g = groups[gid] as Map<String, dynamic>?;
                              if (g == null) return const SizedBox.shrink();
                              final title = g['title'] ?? '';
                              final plist = (g['places'] as List?)?.cast<String>() ?? [];
                              // sort by pos field on place data (fallback to index)
                              plist.sort((a, b) {
                                final pa = placesMap[a] as Map<String, dynamic>? ?? {};
                                final pb = placesMap[b] as Map<String, dynamic>? ?? {};
                                final posa = pa['pos'] is int ? pa['pos'] as int : 0;
                                final posb = pb['pos'] is int ? pb['pos'] as int : 0;
                                return posa.compareTo(posb);
                              });
                              final children = plist.map((pid) {
                                final placeData = placesMap[pid] as Map<String, dynamic>? ?? {};
                                final placeName = placeData['name'] ?? '';
                                final assigned = (placeData['assignees'] as List?)?.cast<String>() ?? [];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    border: Border(
                                      left: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                      right: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                      bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          placeName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: assigned.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(left: 12.0),
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: assigned
                                                      .map((entry) {
                                                        final parts = entry.split('_');
                                                        final label = parts.length >= 3 ? '${parts[1]} ${parts[2]}' : entry;
                                                        return CustomChip(label: label);
                                                      })
                                                      .toList(),
                                                ),
                                              )
                                            : Text(translation(context: context, 'No users assigned'), style: TextStyle(color: Colors.grey)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  // Box around group children for clear visual grouping
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      children: children
                                          .map((w) => Column(
                                                children: [
                                                  // each child already is a Container-like row; keep padding
                                                  Padding(padding: const EdgeInsets.symmetric(vertical: 0.0), child: w),
                                                  // divider between items
                                                  const Divider(height: 1, thickness: 1),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }).toList(),

                            // Render ungrouped places (places not included in any group)
                            Builder(builder: (context) {
                              final ungrouped = placesMap.entries.where((e) {
                                final p = e.value as Map<String, dynamic>;
                                return (p['group'] == null) || (p['group'] == '');
                              }).toList();
                              if (ungrouped.isEmpty) return const SizedBox.shrink();
                              // sort ungrouped by pos
                              ungrouped.sort((a, b) {
                                final pa = a.value as Map<String, dynamic>;
                                final pb = b.value as Map<String, dynamic>;
                                final posa = pa['pos'] is int ? pa['pos'] as int : 0;
                                final posb = pb['pos'] is int ? pb['pos'] as int : 0;
                                return posa.compareTo(posb);
                              });

                              final children = ungrouped.map((e) {
                                final placeData = e.value as Map<String, dynamic>;
                                final placeName = placeData['name'] ?? '';
                                final assigned = (placeData['assignees'] as List?)?.cast<String>() ?? [];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    border: Border(
                                      left: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                      right: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                      bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          placeName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: assigned.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(left: 12.0),
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: assigned
                                                      .map((entry) {
                                                        final parts = entry.split('_');
                                                        final label = parts.length >= 3 ? '${parts[1]} ${parts[2]}' : entry;
                                                        return CustomChip(label: label);
                                                      })
                                                      .toList(),
                                                ),
                                              )
                                            : Text(translation(context: context, 'No users assigned'), style: TextStyle(color: Colors.grey)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // No title for ungrouped section; just render the container
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      children: children
                                          .map((w) => Column(
                                                children: [
                                                  Padding(padding: const EdgeInsets.symmetric(vertical: 0.0), child: w),
                                                  const Divider(height: 1, thickness: 1),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ],
                        ),
                ),
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
