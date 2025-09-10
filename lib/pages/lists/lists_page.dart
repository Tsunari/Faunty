import 'package:faunty/models/user_roles.dart';
import 'package:faunty/pages/catering/catering.dart';
import 'package:faunty/pages/cleaning/cleaning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../program/program_page.dart';
import '../lists/custom_list/add_page.dart';
import 'package:faunty/state_management/user_provider.dart';
import '../../components/tab_page.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/pages/lists/custom_list/attendance_list_widget.dart';
import 'package:faunty/pages/lists/custom_list/schedule_list_widget.dart';
import 'package:faunty/state_management/custom_list_provider.dart';
import 'package:faunty/pages/lists/custom_list/assignment_list_widget.dart';
import 'package:faunty/pages/lists/custom_list/custom_list_shell.dart';
import 'package:faunty/helper/icon_registry.dart';

final lastTabIndexProvider = StateProvider<int?>((ref) => null);

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  final placeId = user?.placeId ?? 'default_place';
  final listsAsync = ref.watch(customListsProvider(placeId));
    return listsAsync.when(
      data: (lists) {
        final tabs = <TabMeta>[
          TabMeta('Cleaning', CleaningPage(), Icons.cleaning_services_outlined),
          TabMeta('Catering', CateringPage(), Icons.restaurant_outlined),
          TabMeta('Program', ProgramPage(), Icons.event_outlined),
        ];
        for (final l in lists) {
          late final Widget pageChild;
          switch (l.type) {
            case CustomListType.attendance:
              pageChild = AttendanceListWidget(placeId: placeId, list: l);
              break;
            case CustomListType.schedule:
              pageChild = ScheduleListWidget(placeId: placeId, list: l);
              break;
            default:
              pageChild = AssignmentListWidget(placeId: placeId, list: l);
          }
          final page = CustomListShell(placeId: placeId, list: l, child: pageChild);
          tabs.add(TabMeta(l.title, page, l.icon != null && l.icon!.kind == 'material' ? iconFromSpec(l.icon) : Icons.list));
        }

        // Only show the Add tab for privileged roles.
        final roleName = user?.role;
        final allowAdd = roleName == UserRole.superuser || roleName == UserRole.hoca || roleName == UserRole.baskan;
        if (allowAdd) {
          tabs.add(TabMeta('Add', const AddPage(), Icons.add));
        }

        return TabPage(
          tabs: tabs,
          tabIndexProvider: lastTabIndexProvider,
          prefsKey: 'lists_last_tab_index',
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading lists: $e')),
    );
  }
}

