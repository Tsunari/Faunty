import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state_management/attendance_provider.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_items_page.dart';
import 'attendance_table.dart';
import 'package:faunty/state_management/user_list_provider.dart';
import 'package:faunty/models/user_entity.dart';
import '../../../firestore/attendance_firestore_service.dart';

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

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Attendance'),
        actions: [
          itemsMeta.isNotEmpty
              ? RoleGate(
                  minRole: UserRole.baskan,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      children: [
                        if (!_useTabs)
                          DropdownButton<String>(
                            value: itemIds.contains(_selectedItem) ? _selectedItem : null,
                            alignment: Alignment.center,
                            underline: const SizedBox.shrink(),
                            onChanged: (val) async {
                              if (val == null) return;
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
                            items: [
                              ...itemsMeta.map((it) => DropdownMenuItem(
                                    value: it['id'] as String? ?? it['name'],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                      child: Text(it['name'] as String? ?? ''),
                                    ),
                                  )),
                              const DropdownMenuItem(
                                value: '__manage__',
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                  child: Text('Manage'),
                                ),
                              ),
                            ],
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
                )
              : const SizedBox.shrink(),
        ],
      ),
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
              ),
            ),
    );
  }
}
