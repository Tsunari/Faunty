import 'package:faunty/features/tracking/presentation/pages/attendance/attendance_viewer.dart';
import 'package:faunty/features/tracking/presentation/pages/statistics/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/presentation/pages/kantin_page.dart';
import 'package:faunty/core/widgets/tab_page.dart';
import 'package:faunty/core/widgets/under_construction.dart';

final trackingTabIndexProvider = StateProvider<int?>((ref) => null);

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      tabs: [
        const TabMeta('Statistics', StatisticsPage(), Icons.bar_chart_outlined),
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