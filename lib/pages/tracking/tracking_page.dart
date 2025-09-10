import 'package:faunty/pages/tracking/attendance/attendance_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../more/kantin_page.dart';
import '../../components/tab_page.dart';
import '../../components/under_construction.dart';

final trackingTabIndexProvider = StateProvider<int?>((ref) => null);

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      tabs: [
        const TabMeta('Statistics', UnderConstructionPage(label: 'Statistics'), Icons.bar_chart_outlined),
        const TabMeta('Attendance', AttendanceViewer(), Icons.checklist_outlined),
        const TabMeta('Custom List Tracking', UnderConstructionPage(label: 'Custom List Tracking'), Icons.list_alt_outlined),
        const TabMeta('Kantin', KantinPage(), Icons.local_cafe_outlined)
      ],
      tabIndexProvider: trackingTabIndexProvider,
      prefsKey: 'tracking_last_tab_index',
    );
  }
}

// replaced by reusable UnderConstructionPage component
