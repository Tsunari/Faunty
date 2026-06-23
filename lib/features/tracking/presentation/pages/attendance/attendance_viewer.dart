import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/core/utils/sort_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/tracking/presentation/controllers/attendance_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faunty/features/tracking/presentation/pages/attendance/attendance_items_page.dart';
import 'package:faunty/features/tracking/presentation/pages/attendance/attendance_table.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/tracking/data/repositories/attendance_firestore_service.dart';
import 'package:faunty/core/widgets/tab_page.dart';

class AttendanceViewer extends ConsumerStatefulWidget {
  const AttendanceViewer({super.key});

  @override
  ConsumerState<AttendanceViewer> createState() => _AttendanceViewerState();
}

class _AttendanceViewerState extends ConsumerState<AttendanceViewer> {
  String _selectedItem = '';
  bool _useTabs = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      final saved = sp.getBool('attendance_use_tabs') ?? true;
      if (!mounted) return;
      setState(() => _useTabs = saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersByCurrentPlaceProvider);
    // final rolesKey = [UserRole.talebe, UserRole.baskan].map((r) => r.name).join(',');
    // final usersAsync = ref.watch(usersByRolesAndPlaceProviderWithOptions({'rolesKey': rolesKey, 'sort': const UserSortOption()})); DOESNT WORK RN
    final currentUser = ref.watch(userProvider);
    final user = currentUser.asData?.value;

    if (user == null) return const Center(child: CircularProgressIndicator());

    final List<UserEntity> users = usersAsync.asData?.value ?? const <UserEntity>[];
    final attendanceAsync = ref.watch(attendanceProvider(user.placeId));
    if (!attendanceAsync.hasValue) return const Center(child: CircularProgressIndicator());
    final Map<String, dynamic> attendance = attendanceAsync.value ?? {};

    final metaAsync = ref.watch(attendanceMetaProvider(user.placeId));
    final meta = metaAsync.asData?.value ?? <String, dynamic>{};
    final List<Map<String, dynamic>> itemsMeta = (meta['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
    final List<String> itemIds = itemsMeta.map((e) => e['id'] as String? ?? '').where((s) => s.isNotEmpty).toList();

    // Load selected item from prefs if not set; AttendanceTable will also handle this case,
    // but we keep a local copy so AppBar dropdown can reflect selection.
    if (_selectedItem.isEmpty) {
      SharedPreferences.getInstance().then((sp) {
        final key = 'attendance_default_${user.placeId}';
        final saved = sp.getString(key);
        String resolved = '';
        if (saved != null && saved.isNotEmpty) {
          if (itemIds.contains(saved)) {
            resolved = saved;
          } else {
            final match = itemsMeta.cast<Map<String, dynamic>?>().firstWhere(
              (e) => e != null && (e['name'] as String? ?? '') == saved,
              orElse: () => null,
            );
            if (match != null) resolved = match['id'] as String? ?? '';
          }
        }
        if (resolved.isEmpty && itemIds.isNotEmpty) resolved = itemIds.first;
        if (!mounted) return;
        setState(() => _selectedItem = resolved);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tabAppBarConfigProvider('Attendance').notifier).state = TabAppBarConfig(
        actions: [
          if (itemsMeta.isNotEmpty)
            RoleGate(
              minRole: UserRole.baskan,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_useTabs)
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        const manageKey = '__manage__';
                        if (val == manageKey) {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AttendanceItemsPage(placeId: user.placeId)));
                          if (!mounted) return;
                          setState(() {});
                          return;
                        }
                        setState(() => _selectedItem = val);
                        final sp = await SharedPreferences.getInstance();
                        await sp.setString('attendance_default_${user.placeId}', val);
                        final metaMap = await AttendanceFirestoreService(user.placeId).getAttendanceMeta();
                        if (metaMap.containsKey('default')) {
                          metaMap.remove('default');
                          await AttendanceFirestoreService(user.placeId).setAttendanceMeta(metaMap);
                        }
                      },
                      itemBuilder: (context) => [
                        ...itemsMeta.map((it) => PopupMenuItem<String>(
                              value: it['id'] as String? ?? it['name'],
                              child: Row(
                                children: [
                                  Icon(Icons.checklist_outlined, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(it['name'] as String? ?? ''),
                                ],
                              ),
                            )),
                        PopupMenuItem<String>(
                          value: '__manage__',
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              const Text('Manage'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
                          color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              itemsMeta.firstWhere((e) => e['id'] == _selectedItem, orElse: () => {'name': ''})['name'] as String? ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  if (_useTabs)
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: translation(context: context, 'Manage'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AttendanceItemsPage(placeId: user.placeId))).then((_) {
                          if (!mounted) return;
                          setState(() {});
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(_useTabs ? Icons.view_list : Icons.tab),
                    tooltip: _useTabs ? translation(context: context, 'Use dropdown') : translation(context: context, 'Use tabs'),
                    onPressed: () async {
                      final next = !_useTabs;
                      final sp = await SharedPreferences.getInstance();
                      await sp.setBool('attendance_use_tabs', next);
                      if (!mounted) return;
                      setState(() => _useTabs = next);
                    },
                  ),
                ],
              ),
            ),
        ],
      );
    });

    return Scaffold(
      appBar: null,
      body: itemsMeta.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      translation(
                        context: context,
                        'No tracking items have been configured yet.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translation(
                        context: context,
                        'Ask a manager to add tracking items or add them yourself.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RoleGate(
                      minRole: UserRole.baskan,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AttendanceItemsPage(placeId: user.placeId)));
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: Text(
                          translation(
                            context: context,
                            'Manage tracking items',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: AttendanceTable(
                users: users,
                attendanceItems: itemsMeta,
                attendance: attendance,
                placeId: user.placeId,
                useTabs: _useTabs,
                selectedItem: _selectedItem,
                onSelectedItemChanged: (val) async {
                  setState(() => _selectedItem = val);
                },
                currentUser: user,
              ),
            ),
    );
  }
}