import 'package:faunty/core/widgets/custom_confirm_dialog.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/lists/presentation/controllers/cleaning_provider.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class CleaningAssignPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  const CleaningAssignPage({super.key, required this.initialData});

  @override
  ConsumerState<CleaningAssignPage> createState() => _CleaningAssignPageState();
}

enum CleaningViewMode { places, byPerson }

class _CleaningAssignPageState extends ConsumerState<CleaningAssignPage> {
  late Map<String, dynamic> places;
  late Map<String, dynamic> groups;
  late List<String> groupOrder;
  bool isSaving = false;
  // Multiple selectable group filters; empty means all groups
  Set<String> selectedGroupFilters = {};
  String searchQuery = '';
  CleaningViewMode viewMode = CleaningViewMode.places;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = Map<String, dynamic>.from(widget.initialData);
    places = Map<String, dynamic>.from(data['places'] ?? {});
    groups = Map<String, dynamic>.from(data['groups'] ?? {});
    groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
    
    var idx = 0;
    for (final pid in places.keys.toList()) {
      final p = places[pid] as Map<String, dynamic>;
      if (p['pos'] == null) p['pos'] = idx;
      idx++;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addPlaceDialog() async {
    final controller = TextEditingController();
    String? selectedGroup;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              translation(context: ctx, 'Add Place'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Place name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: selectedGroup,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Group (Optional)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(translation(context: context, 'No Group')),
                  ),
                  ...groupOrder.map((gid) {
                    final g = groups[gid] as Map<String, dynamic>?;
                    final title = g?['title'] ?? gid;
                    return DropdownMenuItem<String?>(value: gid, child: Text(title));
                  }),
                ],
                onChanged: (val) => setDialogState(() => selectedGroup = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context: context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'name': controller.text.trim(),
                'group': selectedGroup,
              }),
              child: Text(translation(context: context, 'Add')),
            ),
          ],
        ),
      ),
    );
    
    if (result != null && result['name'] != null && result['name'].isNotEmpty) {
      final service = ref.read(cleaningFirestoreServiceProvider);
      final id = await service.addPlace(result['name']);
      setState(() {
        places[id] = {
          'name': result['name'],
          'assignees': <String>[],
          'group': result['group'],
        };
        if (result['group'] != null) {
          final plist = (groups[result['group']]!['places'] as List?)?.cast<String>() ?? [];
          if (!plist.contains(id)) plist.add(id);
          groups[result['group']]!['places'] = plist;
        }
      });
      if (mounted) {
        showCustomSnackBar(context, translation(context: context, 'Place added successfully'));
      }
    }
  }

  void _editPlaceDialog(String placeId) async {
    final place = places[placeId] as Map<String, dynamic>;
    final controller = TextEditingController(text: place['name']);
    String? selectedGroup = place['group'];
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              translation(context: ctx, 'Edit Place'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Place name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: selectedGroup,
                decoration: InputDecoration(
                  labelText: translation(context: context, 'Group'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(translation(context: context, 'No Group')),
                  ),
                  ...groupOrder.map((gid) {
                    final g = groups[gid] as Map<String, dynamic>?;
                    final title = g?['title'] ?? gid;
                    return DropdownMenuItem<String?>(value: gid, child: Text(title));
                  }),
                ],
                onChanged: (val) => setDialogState(() => selectedGroup = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context: context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'name': controller.text.trim(),
                'group': selectedGroup,
              }),
              child: Text(translation(context: context, 'Save')),
            ),
          ],
        ),
      ),
    );
    
    if (result != null && result['name'] != null && result['name'].isNotEmpty) {
      final service = ref.read(cleaningFirestoreServiceProvider);
      await service.updatePlace(placeId, result['name']);
      
      final oldGroup = place['group'] as String?;
      setState(() {
        place['name'] = result['name'];
        place['group'] = result['group'];
        places[placeId] = place;
        
        if (oldGroup != result['group']) {
          if (oldGroup != null && groups.containsKey(oldGroup)) {
            final plist = (groups[oldGroup]!['places'] as List?)?.cast<String>() ?? [];
            plist.remove(placeId);
            groups[oldGroup]!['places'] = plist;
          }
          if (result['group'] != null) {
            final plist = (groups[result['group']]!['places'] as List?)?.cast<String>() ?? [];
            if (!plist.contains(placeId)) plist.add(placeId);
            groups[result['group']]!['places'] = plist;
          }
        }
      });
      await service.setCleaning(places);
      await service.setGroups(groups);
      if (mounted) {
        showCustomSnackBar(context, translation(context: context, 'Place updated successfully'));
      }
    }
  }

  Future<void> _deletePlace(String placeId) async {
    final placeName = places[placeId]?['name'] ?? 'Unknown';
    final confirm = await showConfirmDialog(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            '${translation(context: context, 'Delete')} "$placeName"?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            translation(context: context, 'This action cannot be undone.'),
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
      if (mounted) {
        showCustomSnackBar(context, translation(context: context, 'Place deleted'));
      }
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
    try {
      final service = ref.read(cleaningFirestoreServiceProvider);
      await service.setCleaning(places);
      await service.setGroups(groups);
      if (mounted) {
        showCustomSnackBar(context, translation(context: context, 'Saved successfully'));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          translation(context: context, 'Error saving changes'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  List<MapEntry<String, dynamic>> _getFilteredPlaces() {
    var entries = places.entries.toList();
    
    // Filter by group set (when not empty)
    if (selectedGroupFilters.isNotEmpty) {
      entries = entries.where((e) {
        final place = e.value as Map<String, dynamic>;
        final g = place['group'] as String?;
        return g != null && selectedGroupFilters.contains(g);
      }).toList();
    }
    
    // Filter by search
    if (searchQuery.isNotEmpty) {
      entries = entries.where((e) {
        final place = e.value as Map<String, dynamic>;
        final name = (place['name'] ?? '').toString().toLowerCase();
        final assignees = (place['assignees'] as List?)?.cast<String>() ?? [];
        final assigneeNames = assignees.map((a) {
          final parts = a.split('_');
          return parts.length >= 3 ? '${parts[1]} ${parts[2]}'.toLowerCase() : '';
        }).join(' ');
        return name.contains(searchQuery.toLowerCase()) || 
               assigneeNames.contains(searchQuery.toLowerCase());
      }).toList();
    }
    
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rolesKey = [UserRole.talebe, UserRole.baskan].map((r) => r.name).join(',');
    final usersAsync = ref.watch(usersByRolesAndPlaceProvider(rolesKey));

    return Scaffold(
        appBar: CustomAppBar(
          title: translation(context: context, 'Edit Assignments'),
          useModern: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SegmentedButton<CleaningViewMode>(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(
                    value: CleaningViewMode.places,
                    icon: const Icon(Icons.view_list_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: CleaningViewMode.byPerson,
                    icon: const Icon(Icons.people_outline, size: 16),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (s) => setState(() => viewMode = s.first),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_outlined),
              tooltip: translation(context: context, 'Manage Groups'),
              onPressed: () => _showGroupsDialog(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.add_location_alt_outlined),
                tooltip: translation(context: context, 'Add Place'),
                onPressed: _addPlaceDialog,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: translation(context: context, 'Search...'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => searchQuery = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: translation(context: context, 'Filter by group'),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            selectedGroupFilters.isEmpty ? Icons.filter_list : Icons.filter_list_alt,
                            size: 24,
                            color: selectedGroupFilters.isEmpty ? theme.iconTheme.color : theme.colorScheme.primary,
                          ),
                          if (selectedGroupFilters.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  selectedGroupFilters.length.toString(),
                                  style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _openGroupFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
          // Tab view
          Expanded(
            child: viewMode == CleaningViewMode.places
                ? _buildPlacesView(usersAsync, isDark, theme)
                : _buildPersonView(usersAsync, isDark, theme),
          ),
        ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: isSaving ? null : _saveAll,
          tooltip: translation(context: context, 'Save'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          child: isSaving
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white),
                )
              : const Icon(Icons.save),
        ),
      );
  }

  void _openGroupFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        translation(context: context, 'Filter Groups'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          selectedGroupFilters.clear();
                          setSheetState(() {});
                          Navigator.pop(context); // Close only when all cleared per requirement
                        },
                        child: Text(translation(context: context, 'All Groups')),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        itemCount: groupOrder.length,
                        itemBuilder: (context, index) {
                          final gid = groupOrder[index];
                          final g = groups[gid] as Map<String, dynamic>?;
                          final title = g?['title'] ?? gid;
                          final selected = selectedGroupFilters.contains(gid);
                          return CheckboxListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(title, overflow: TextOverflow.ellipsis),
                            value: selected,
                            onChanged: (_) {
                              if (selected) {
                                selectedGroupFilters.remove(gid);
                              } else {
                                selectedGroupFilters.add(gid);
                              }
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          selectedGroupFilters.clear();
                          setSheetState(() {});
                        },
                        child: Text(translation(context: context, 'Clear')),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {}); // refresh list
                        },
                        icon: const Icon(Icons.check),
                        label: Text(translation(context: context, 'Apply')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {}); // ensure parent rebuild (in case closed via All Groups)
  }

  Widget _buildPlacesView(AsyncValue usersAsync, bool isDark, ThemeData theme) {
    return usersAsync.when(
      data: (users) {
        final filteredEntries = _getFilteredPlaces();
        
        if (places.isEmpty) {
          return _buildEmptyState();
        }
        
        if (filteredEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  translation(context: context, 'No places found'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      // Clear all selected group filters
                      selectedGroupFilters.clear();
                    });
                  },
                  child: Text(translation(context: context, 'Clear filters')),
                ),
              ],
            ),
          );
        }
        
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: filteredEntries.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = filteredEntries.removeAt(oldIndex);
              filteredEntries.insert(newIndex, moved);
              
              final newMap = <String, dynamic>{};
              for (final e in filteredEntries) {
                newMap[e.key] = e.value;
              }
              places = Map<String, dynamic>.from(newMap);
              
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
            final entry = filteredEntries[idx];
            final placeId = entry.key;
            final place = entry.value as Map<String, dynamic>;
            final placeName = place['name'] ?? '';
            final assignees = (place['assignees'] as List?)?.cast<String>() ?? [];
            final currentGroup = place['group'] as String?;
            
            return _buildPlaceCard(
              key: ValueKey(placeId),
              placeId: placeId,
              placeName: placeName,
              assignees: assignees,
              currentGroup: currentGroup,
              users: users,
              idx: idx,
              isDark: isDark,
              theme: theme,
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.colorScheme.secondary),
      ),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('${translation(context: context, 'Error loading users')}: $e'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonView(AsyncValue usersAsync, bool isDark, ThemeData theme) {
    return usersAsync.when(
      data: (users) {
        final Map<UserEntity, List<String>> personAssignments = {
          for (final u in users) u: []
        };

        // Map place assignments to user objects by robust parsing
        for (final placeEntry in places.entries) {
          final place = placeEntry.value as Map<String, dynamic>;
          final placeGroup = place['group'] as String?;
          // Apply group filter if selected
          if (selectedGroupFilters.isNotEmpty && (placeGroup == null || !selectedGroupFilters.contains(placeGroup))) {
            continue;
          }
          final placeAssignees = (place['assignees'] as List?)?.cast<String>() ?? [];
          for (final encoded in placeAssignees) {
            final parsed = _parseEncodedAssignee(encoded);
            if (parsed == null) continue;
            final uid = parsed['uid'] as String;
            final first = parsed['first'] as String;
            final last = parsed['last'] as String;
            final user = users.firstWhere(
              (u) => u.uid == uid,
              orElse: () => UserEntity(
                uid: uid,
                email: '',
                firstName: first,
                lastName: last,
                role: UserRole.user,
                placeId: '',
                isPlaceholder: true,
              ),
            );
            personAssignments.putIfAbsent(user, () => []);
            personAssignments[user]!.add(placeEntry.key);
          }
        }

        final sortedEntries = personAssignments.entries.toList()
          ..sort((a, b) {
            final aCount = a.value.length;
            final bCount = b.value.length;
            if (bCount != aCount) return bCount.compareTo(aCount);
            return _displayName(a.key).compareTo(_displayName(b.key));
          });

        // Apply search filtering for person view
        List<MapEntry<UserEntity, List<String>>> filteredEntries = sortedEntries;
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase().trim();
            filteredEntries = sortedEntries.where((entry) {
            final userName = _displayName(entry.key).toLowerCase();
            final placeMatches = entry.value.any((pid) {
              final place = places[pid] as Map<String, dynamic>?;
              final pname = (place?['name'] ?? '').toString().toLowerCase();
              return pname.contains(q);
            });
            return userName.contains(q) || placeMatches;
          }).toList();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredEntries.length,
          itemBuilder: (context, idx) {
            final entry = filteredEntries[idx];
            final user = entry.key;
            final name = _displayName(user);
            final placeIds = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      placeIds.length.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${placeIds.length} ${translation(context: context, placeIds.length == 1 ? 'place' : 'places')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: placeIds.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              translation(context: context, 'No assignments'),
                              style: TextStyle(color: theme.disabledColor),
                            ),
                          ),
                        ]
                      : placeIds.map((placeId) {
                          final place = places[placeId] as Map<String, dynamic>?;
                          final placeName = place?['name'] ?? placeId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.place, size: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Text(placeName)),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _toggleAssignee(placeId, user),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.colorScheme.secondary),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 80, color: Theme.of(context).disabledColor),
            const SizedBox(height: 24),
            Text(
              translation(context: context, 'No places yet.'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              translation(context: context, 'Add your first cleaning place to get started'),
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: Text(translation(context: context, 'Create Place')),
              onPressed: _addPlaceDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard({
    required Key key,
    required String placeId,
    required String placeName,
    required List<String> assignees,
    required String? currentGroup,
    required List users,
    required int idx,
    required bool isDark,
    required ThemeData theme,
  }) {
    String? groupName;
    if (currentGroup != null && groups.containsKey(currentGroup)) {
      final g = groups[currentGroup] as Map<String, dynamic>?;
      groupName = g?['title'];
    }
    
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: idx,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.drag_indicator, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (groupName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            groupName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  tooltip: translation(context: context, 'Edit'),
                  onPressed: () => _editPlaceDialog(placeId),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20),
                  tooltip: translation(context: context, 'Delete'),
                  onPressed: () => _deletePlace(placeId),
                ),
              ],
            ),
          ),
          // Assignees
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 6),
                    Text(
                      translation(context: context, 'Assigned People'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        assignees.length.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    // Warning icon if orphan assignees exist
                    if (_hasOrphanAssignees(assignees, users)) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: translation(context: context, 'Some assigned users are missing'),
                        child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orangeAccent),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildAssigneeChips(
                    theme: theme,
                    users: users.cast<UserEntity>(),
                    assignees: assignees,
                    placeId: placeId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(UserEntity user) {
    // Replace underscores in firstName, keep multiple name parts
    final cleanFirst = user.firstName.replaceAll('_', ' ').trim();
    final cleanLast = user.lastName.replaceAll('_', ' ').trim();
    if (cleanFirst.isEmpty && cleanLast.isEmpty) return translation(context: context, 'Unknown');
    if (cleanLast.isEmpty) return cleanFirst; // some placeholders may not have surname
    if (cleanFirst.isEmpty) return cleanLast;
    return '$cleanFirst $cleanLast';
  }

  bool _hasOrphanAssignees(List<String> assignees, List users) {
    return assignees.any((entry) {
      final parsed = _parseEncodedAssignee(entry);
      if (parsed == null) return false;
      final uid = parsed['uid'] as String;
      return !users.any((u) => u.uid == uid);
    });
  }

  List<Widget> _buildAssigneeChips({
    required ThemeData theme,
    required List<UserEntity> users,
    required List<String> assignees,
    required String placeId,
  }) {
    // Build full list: existing users + placeholder entries for orphan assignments
    final List<UserEntity> list = [...users];
    for (final entry in assignees) {
      final parsed = _parseEncodedAssignee(entry);
      if (parsed == null) continue;
      final uid = parsed['uid'] as String;
      if (!list.any((u) => u.uid == uid)) {
        list.add(UserEntity(
          uid: uid,
          email: '',
          firstName: parsed['first'] as String,
          lastName: parsed['last'] as String,
          role: UserRole.user,
          placeId: '',
          isPlaceholder: true,
        ));
      }
    }
    // Preserve original order: users list order, then orphan placeholders appended

    return list.map((user) {
      final encoded = '${user.uid}_${user.firstName}_${user.lastName}';
      final isAssigned = assignees.contains(encoded);
      final missing = !users.any((u) => u.uid == user.uid); // treat as missing only if not in Firestore list
      final bg = missing
          ? Colors.orange.withValues(alpha: 0.12)
          : (isAssigned ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainer);
      final borderColor = missing
          ? Colors.orange.withValues(alpha: 0.6)
          : (isAssigned ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.12));
      return GestureDetector(
        onTap: () => _toggleAssignee(placeId, user),
        child: Tooltip(
          message: missing
              ? translation(context: context, 'User no longer exists')
              : (isAssigned ? translation(context: context, 'Tap to remove') : translation(context: context, 'Tap to assign')),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isAssigned ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (missing) ...[
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                ],
                Text(
                  _displayName(user),
                  style: TextStyle(
                    color: missing
                        ? Colors.orange
                        : (isAssigned ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color),
                    fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Map<String, String>? _parseEncodedAssignee(String entry) {
    // Expected format: uid_first_last, but uid may itself contain underscores.
    // Strategy: last two underscore-separated segments are first and last; everything before is uid.
    final parts = entry.split('_');
    if (parts.length < 3) return null; // invalid format
    final last = parts.last;
    final first = parts[parts.length - 2];
    final uid = parts.sublist(0, parts.length - 2).join('_');
    return {
      'uid': uid,
      'first': first,
      'last': last,
    };
  }

  void _showGroupsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => EditGroupsDialog(
        initialGroups: Map<String, dynamic>.from(groups),
        initialOrder: List<String>.from(groupOrder),
        onSave: (newGroups, newOrder) async {
          final service = ref.read(cleaningFirestoreServiceProvider);
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
          if (mounted) {
            showCustomSnackBar(context, translation(context: context, 'Groups updated'));
          }
        },
      ),
    );
  }
}

// Groups Dialog remains largely the same but with improved UI
typedef EditGroupsOnSave = Future<void> Function(Map<String, dynamic> groups, List<String> order);

class EditGroupsDialog extends StatefulWidget {
  final Map<String, dynamic> initialGroups;
  final List<String> initialOrder;
  final EditGroupsOnSave onSave;

  const EditGroupsDialog({
    super.key,
    required this.initialGroups,
    required this.initialOrder,
    required this.onSave,
  });

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
    final title = groups[id]?['title'] ?? id;
    final confirm = await showConfirmDialog(
      context: context,
      content: Text('${translation(context: context, 'Delete group')} "$title"?'),
    );
    if (confirm == true) {
      setState(() {
        groups.remove(id);
        order.remove(id);
      });
    }
  }

  Future<void> _editGroupTitle(String id) async {
    final controller = TextEditingController(text: groups[id]?['title'] ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            translation(context: ctx, 'Edit Group'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: translation(context: ctx, 'Group title'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translation(context: context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(translation(context: context, 'Save')),
          ),
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
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined),
          const SizedBox(width: 12),
          Text(
            translation(context: context, 'Manage Groups'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: order.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final moved = order.removeAt(oldIndex);
                      order.insert(newIndex, moved);
                    });
                  },
                  itemBuilder: (context, index) {
                    final id = order[index];
                    final g = groups[id] as Map<String, dynamic>? ?? {};
                    final title = g['title'] ?? id;
                    final placeCount = (g['places'] as List?)?.length ?? 0;
                    return Card(
                      key: ValueKey(id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            child: Text(
                              placeCount.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$placeCount ${translation(context: context, placeCount == 1 ? 'place' : 'places')}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: translation(context: context, 'Edit'),
                              onPressed: () => _editGroupTitle(id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: translation(context: context, 'Delete'),
                              onPressed: () => _deleteGroup(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.folder_off, size: 48, color: theme.disabledColor),
                    const SizedBox(height: 12),
                    Text(
                      translation(context: context, 'No groups yet.'),
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newController,
                    decoration: InputDecoration(
                      hintText: translation(context: context, 'New group title'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.add),
                    ),
                    onSubmitted: (_) => _addGroup(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addGroup,
                  icon: Icon(Icons.add),
                  label: Text(translation(context: context, 'Add')),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(translation(context: context, 'Cancel')),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.onSave(groups, order);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(translation(context: context, 'Save')),
        ),
      ],
    );
  }
}