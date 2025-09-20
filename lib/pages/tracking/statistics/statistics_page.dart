import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../state_management/user_provider.dart';
import '../../../state_management/attendance_provider.dart';
import '../../../tools/translation_helper.dart';
import '../attendance/attendance_items_page.dart';
import 'statistics_widgets.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});
  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  String _selectedItem = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.asData?.value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final attendanceAsync = ref.watch(attendanceProvider(user.placeId));
    final metaAsync = ref.watch(attendanceMetaProvider(user.placeId));
    if (!attendanceAsync.hasValue) return const Center(child: CircularProgressIndicator());
    final attendance = attendanceAsync.value ?? <String, dynamic>{};
    final meta = metaAsync.asData?.value ?? <String, dynamic>{};
    final items = (meta['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];

    // initialize selection from prefs once we know items
    if (_selectedItem.isEmpty && items.isNotEmpty) {
      SharedPreferences.getInstance().then((sp) {
        final saved = sp.getString('stats_default_${user.placeId}');
        if (!mounted) return;
        if (saved != null && items.any((e) => e['id'] == saved || e['name'] == saved)) {
          setState(() => _selectedItem = saved);
        } else {
          setState(() => _selectedItem = items.first['id'] as String? ?? '');
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context: context, 'Statistics')),
        actions: [
          if (items.isNotEmpty)
            DropdownButton<String>(
              value: items.any((e) => e['id'] == _selectedItem) ? _selectedItem : null,
              underline: const SizedBox.shrink(),
              onChanged: (val) async {
                if (val == null) return;
                if (!mounted) return;
                setState(() => _selectedItem = val);
                final sp = await SharedPreferences.getInstance();
                await sp.setString('stats_default_${user.placeId}', val);
              },
              items: [
                for (final it in items)
                  DropdownMenuItem(
                    value: it['id'] as String,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      child: Text(it['name'] as String? ?? ''),
                    ),
                  ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: translation(context: context, 'Manage'),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceItemsPage(placeId: user.placeId)));
              if (!mounted) return;
              setState(() {});
            },
          )
        ],
      ),
      body: _selectedItem.isEmpty || items.isEmpty
          ? Center(child: Text(translation(context: context, 'Create a tracking item to see statistics.')))
          : StatisticsWidgets(
              attendance: attendance,
              itemId: _selectedItem,
              itemMeta: items.firstWhere((e) => e['id'] == _selectedItem, orElse: () => items.first),
            ),
    );
  }
}
