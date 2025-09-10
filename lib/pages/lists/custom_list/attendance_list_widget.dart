import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/state_management/attendance_provider.dart';
import 'package:faunty/state_management/user_list_provider.dart';
import '../../tracking/attendance/attendance_table.dart';

class AttendanceListWidget extends ConsumerWidget {
  final String placeId;
  final CustomList list;
  const AttendanceListWidget({super.key, required this.placeId, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // reuse existing attendance providers where possible
    final usersAsync = ref.watch(usersByCurrentPlaceProvider);
    final attendanceAsync = ref.watch(attendanceProvider(placeId));
    final attendanceItems = list.meta['sessions'] as List<Map<String, dynamic>>? ?? [];

    return usersAsync.when(
      data: (users) {
        final attendanceMap = attendanceAsync.asData?.value ?? {};
        return AttendanceTable(
          users: users,
          attendanceItems: attendanceItems,
          attendance: attendanceMap,
          placeId: placeId,
          useTabs: true,
          selectedItem: attendanceItems.isNotEmpty ? (attendanceItems.first['id'] as String? ?? '') : '',
          onSelectedItemChanged: (s) {},
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading users: $e')),
    );
  }
}
