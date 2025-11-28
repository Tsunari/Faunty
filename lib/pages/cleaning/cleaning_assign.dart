import 'package:faunty/components/custom_confirm_dialog.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/user_list_provider.dart';
import '../../state_management/cleaning_provider.dart';
import 'package:faunty/components/custom_app_bar.dart';

class CleaningAssignPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData; // expects { places: {...}, groups: {...}, order: [...], groupOrder: [...] }
  const CleaningAssignPage({super.key, required this.initialData});

  @override
  ConsumerState<CleaningAssignPage> createState() => _CleaningAssignPageState();
}

class _CleaningAssignPageState extends ConsumerState<CleaningAssignPage> {
  late Map<String, dynamic> places;
  late Map<String, dynamic> groups;
  late List<String> groupOrder;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
  final data = Map<String, dynamic>.from(widget.initialData);
  places = Map<String, dynamic>.from(data['places'] ?? {});
  groups = Map<String, dynamic>.from(data['groups'] ?? {});
  groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
    // ensure every place has a 'pos' (fallback to current index)
    var idx = 0;
    for (final pid in places.keys.toList()) {
      final p = places[pid] as Map<String, dynamic>;
      if (p['pos'] == null) p['pos'] = idx;
      idx++;
    }
  }

  void _addPlaceDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context: context, 'Add Place')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: translation(context: context, 'Place name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(translation(context: context, 'Add'))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      // Persist via service so order is managed server-side
      final service = ref.read(cleaningFirestoreServiceProvider);
      final id = await service.addPlace(result);
      // Update local view
      setState(() {
        places[id] = {'name': result, 'assignees': <String>[], 'group': null};
      });
    }
  }

  // Group management is handled by EditGroupsDialog below

  void _editPlaceDialog(String placeId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context: context, 'Edit Place')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: translation(context: context, 'Place name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(translation(context: context, 'Save'))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final service = ref.read(cleaningFirestoreServiceProvider);
      await service.updatePlace(placeId, result);
      setState(() {
        // update local copy (service.updatePlace will also preserve order)
        places[placeId]['name'] = result;
      });
    }
  }

  Future<void> _deletePlace(String placeId, String placeName) async {
    final confirm = await showConfirmDialog(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
        'Delete $placeName?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
        'This action cannot be undone.',
        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
        textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (confirm == true) {
      final service = ref.read(cleaningFirestoreServiceProvider);
      await service.deletePlace(placeId);
      setState(() {
        places.remove(placeId);
        // Remove from any group locally
        for (final g in groups.entries) {
          final gMap = Map<String, dynamic>.from(g.value as Map<String, dynamic>);
          final plist = (gMap['places'] as List?)?.cast<String>() ?? [];
          if (plist.contains(placeId)) {
            plist.remove(placeId);
            gMap['places'] = plist;
            groups[g.key] = gMap;
          }
        }
      });
    }
  }

  void _toggleAssignee(String placeId, dynamic user) {
    setState(() {
      final assignees = List<String>.from(places[placeId]['assignees'] ?? []);
      final entry = '${user.uid}_${user.firstName}_${user.lastName}';
      final exists = assignees.contains(entry);
      if (exists) {
        assignees.remove(entry);
      } else {
        assignees.add(entry);
      }
      places[placeId]['assignees'] = assignees;
    });
  }

  Future<void> _saveAll() async {
    setState(() => isSaving = true);
    final service = ref.read(cleaningFirestoreServiceProvider);
    // ensure groups are persisted as well
    await service.setCleaning(places);
    await service.setGroups(groups);
    setState(() => isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rolesKey = [UserRole.talebe, UserRole.baskan].map((r) => r.name).join(',');
    final usersAsync = ref.watch(usersByRolesAndPlaceProvider(rolesKey));

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Edit Assignments'),
        useModern: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add),
              tooltip: translation(context: context, 'Add Place'),
              onPressed: _addPlaceDialog,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.folder_outlined),
              tooltip: translation(context: context, 'Edit Groups'),
              onPressed: () async {
                // Open dialog to manage groups (list, add, edit, delete)
                await showDialog<void>(
                  context: context,
                  builder: (context) => EditGroupsDialog(
                    initialGroups: Map<String, dynamic>.from(groups),
                    initialOrder: List<String>.from(groupOrder),
                    onSave: (newGroups, newOrder) async {
                      final service = ref.read(cleaningFirestoreServiceProvider);
                      // Remove references to deleted groups from places
                      final deletedGroupIds = groups.keys.where((k) => !newGroups.containsKey(k)).toSet();
                      var changed = false;
                      for (final pid in places.keys.toList()) {
                        final p = places[pid] as Map<String, dynamic>;
                        final pg = p['group'] as String?;
                        if (pg != null && deletedGroupIds.contains(pg)) {
                          p['group'] = null;
                          places[pid] = p;
                          changed = true;
                        }
                      }
                      if (changed) await service.setCleaning(places);
                      await service.setGroups(newGroups);
                      setState(() {
                        groups = Map<String, dynamic>.from(newGroups);
                        groupOrder = List<String>.from(newOrder);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (places.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      translation(context: context, 'No places yet.'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(translation(context: context, 'Create Place')),
                      onPressed: _addPlaceDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Use ReorderableListView so places can be re-ordered using a drag handle
          final entries = places.entries.toList();
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            itemCount: entries.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                // Adjust newIndex when removing the old item
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = entries.removeAt(oldIndex);
                entries.insert(newIndex, moved);
                // Rebuild the places map preserving new order
                final newMap = <String, dynamic>{};
                for (final e in entries) {
                  newMap[e.key] = e.value;
                }
                places = Map<String, dynamic>.from(newMap);
                // Update positions according to new global order and persist
                int pos = 0;
                for (final pid in places.keys) {
                  final p = places[pid] as Map<String, dynamic>;
                  p['pos'] = pos;
                  places[pid] = p;
                  pos++;
                }
                final service = ref.read(cleaningFirestoreServiceProvider);
                service.setCleaning(places);
              });
            },
            buildDefaultDragHandles: false,
            itemBuilder: (context, idx) {
              final entry = entries[idx];
              final placeId = entry.key;
              final place = entry.value as Map<String, dynamic>;
              final placeName = place['name'] ?? '';
              final assignees = (place['assignees'] as List?)?.cast<String>() ?? [];
                final currentGroup = place['group'] as String?;

              return Card(
                key: ValueKey(placeId),
                margin: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Drag handle (3-line icon)
                          ReorderableDragStartListener(
                            index: idx,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Icon(Icons.drag_handle, color: Theme.of(context).iconTheme.color),
                            ),
                          ),
                          Expanded(
                            child: Text(placeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: translation(context: context, 'Edit Place'),
                            onPressed: () => _editPlaceDialog(placeId, placeName),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: translation(context: context, 'Delete Place'),
                            onPressed: () => _deletePlace(placeId, placeName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Group selector
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Text('Group: '),
                            const SizedBox(width: 8),
                            DropdownButton<String?>(
                              value: currentGroup,
                              hint: Text(translation(context: context, 'None')),
                              items: [
                                DropdownMenuItem<String?>(value: null, child: Text(translation(context: context, 'None'))),
                                ...groupOrder.map((gid) {
                                  final g = groups[gid] as Map<String, dynamic>?;
                                  final title = g == null ? gid : (g['title'] ?? gid);
                                  return DropdownMenuItem<String?>(value: gid, child: Text(title));
                                }).toList()
                              ],
                              onChanged: (val) async {
                                // Update local mapping and groups lists
                                final oldGroup = place['group'] as String?;
                                setState(() {
                                  place['group'] = val;
                                  places[placeId] = place;
                                  // remove from old group
                                  if (oldGroup != null && groups.containsKey(oldGroup)) {
                                    final plist = (groups[oldGroup]!['places'] as List?)?.cast<String>() ?? [];
                                    plist.remove(placeId);
                                    groups[oldGroup]!['places'] = plist;
                                  }
                                  // add to new group
                                  if (val != null) {
                                    final plist = (groups[val]!['places'] as List?)?.cast<String>() ?? [];
                                    if (!plist.contains(placeId)) plist.add(placeId);
                                    groups[val]!['places'] = plist;
                                  }
                                });
                                // Persist groups and places
                                final service = ref.read(cleaningFirestoreServiceProvider);
                                await service.setCleaning(places);
                                await service.setGroups(groups);
                              },
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 120, // Set your desired max height here
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: [
                              ...users.map((user) {
                                final userName = '${user.firstName} ${user.lastName}';
                                final entry = '${user.uid}_${user.firstName}_${user.lastName}';
                                final isAssigned = assignees.contains(entry);
                                return FilterChip(
                                  label: Text(userName),
                                  selected: isAssigned,
                                  onSelected: (_) => _toggleAssignee(placeId, user),
                                );
                              }),
                              // Show assigned users as Chips (for visual feedback)
                              ...assignees.where((entry) {
                                final parts = entry.split('_');
                                return parts.length >= 3 && !users.any((u) => u.uid == parts[0]);
                              }).map((entry) {
                                final parts = entry.split('_');
                                final label = parts.length >= 3 ? '${parts[1]} ${parts[2]}' : entry;
                                return Chip(label: Text(label));
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        error: (e, st) => Center(child: Text('Error loading users: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving ? null : _saveAll,
        tooltip: translation(context: context, 'Save'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: isSaving ? const Icon(Icons.save) : const Icon(Icons.save),
        // child: isSaving ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary) : const Icon(Icons.save),
      ),
    );
  }
}

typedef EditGroupsOnSave = Future<void> Function(Map<String, dynamic> groups, List<String> order);

class EditGroupsDialog extends StatefulWidget {
  final Map<String, dynamic> initialGroups;
  final List<String> initialOrder;
  final EditGroupsOnSave onSave;

  const EditGroupsDialog({super.key, required this.initialGroups, required this.initialOrder, required this.onSave});

  @override
  State<EditGroupsDialog> createState() => _EditGroupsDialogState();
}

class _EditGroupsDialogState extends State<EditGroupsDialog> {
  late Map<String, dynamic> groups;
  late List<String> order;
  final _newController = TextEditingController();

  @override
  void initState() {
    super.initState();
    groups = Map<String, dynamic>.from(widget.initialGroups);
    order = List<String>.from(widget.initialOrder);
  }

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    final title = _newController.text.trim();
    if (title.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      groups[id] = {'title': title, 'places': <String>[]};
      order.add(id);
      _newController.clear();
    });
  }

  Future<void> _deleteGroup(String id) async {
    setState(() {
      groups.remove(id);
      order.remove(id);
    });
  }

  Future<void> _editGroupTitle(String id) async {
    final controller = TextEditingController(text: groups[id]?['title'] ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context: context, 'Edit Group')),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: translation(context: context, 'Group title'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context: context, 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(translation(context: context, 'Save'))),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      setState(() {
        groups[id]['title'] = title;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(translation(context: context, 'Manage Groups')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // list of groups
            if (order.isNotEmpty)
              ...order.map((id) {
                final g = groups[id] as Map<String, dynamic>? ?? {};
                final title = g['title'] ?? id;
                return ListTile(
                  key: ValueKey(id),
                  title: Text(title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit), onPressed: () => _editGroupTitle(id)),
                      IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteGroup(id)),
                    ],
                  ),
                );
              }).toList()
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translation(context: context, 'No groups yet.')),
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _newController, decoration: InputDecoration(hintText: translation(context: context, 'New group title')))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addGroup, child: Text(translation(context: context, 'Add'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context: context, 'Cancel'))),
        ElevatedButton(
          onPressed: () async {
            await widget.onSave(groups, order);
            Navigator.pop(context);
          },
          child: Text(translation(context: context, 'Save')),
        ),
      ],
    );
  }
}
