import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/tracking/presentation/controllers/attendance_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/features/lists/presentation/pages/pdf_preview_page.dart';
import 'package:faunty/core/utils/pdf_generator/statistics_pdf_layout.dart';

import 'package:faunty/features/tracking/presentation/pages/statistics/statistics_widgets.dart';
import 'package:faunty/features/tracking/presentation/pages/statistics/stats_utils.dart';
import 'package:faunty/core/widgets/tab_page.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});
  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  String _selectedItem = '';
  String? _selectedUser;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSelectedUser();
  }

  Future<void> _loadSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('statistics_selected_user');
    if (saved != null && mounted) {
      setState(() {
        _selectedUser = saved;
      });
    }
  }

  Future<void> _saveSelectedUser(String? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove('statistics_selected_user');
    } else {
      await prefs.setString('statistics_selected_user', user);
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tabAppBarConfigProvider('Statistics').notifier).state = TabAppBarConfig(
        actions: [
          if (items.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _captureAndShare(context),
            ),
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (!mounted) return;
                setState(() => _selectedItem = val);
                final sp = await SharedPreferences.getInstance();
                await sp.setString('stats_default_${user.placeId}', val);
              },
              itemBuilder: (context) => [
                for (final it in items)
                  PopupMenuItem(
                    value: it['id'] as String,
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(it['name'] as String? ?? ''),
                      ],
                    ),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items.firstWhere((e) => e['id'] == _selectedItem, orElse: () => {'name': ''})['name'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });

    return Scaffold(
      appBar: null,
      body: _selectedItem.isEmpty || items.isEmpty
          ? Center(child: Text(translation(context: context, 'Create a tracking item to see statistics.')))
          : Padding(
            padding: const EdgeInsets.fromLTRB(0, 96, 0, 96),
            child: StatisticsWidgets(
                attendance: attendance,
                itemId: _selectedItem,
                itemMeta: items.firstWhere((e) => e['id'] == _selectedItem, orElse: () => items.first),
                selectedUser: _selectedUser,
                onUserChanged: (val) {
                  setState(() => _selectedUser = val);
                  _saveSelectedUser(val);
                },
                placeId: user.placeId,
                screenshotKey: _repaintKey,
              ),
          ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes != null) {
        final file = XFile.fromData(pngBytes, name: 'statistics_screenshot.png', mimeType: 'image/png');
        await SharePlus.instance.share(ShareParams(files: [file], text: 'Statistics Screenshot'));
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
  }

  // Future<void> _generatePdf(BuildContext context, Map<String, dynamic> attendance, Map<String, dynamic> itemMeta, String placeId) async {
  //   final itemName = itemMeta['name'] as String? ?? 'Unknown';
  //   final itemId = itemMeta['id'] as String;
  //   final now = DateTime.now();
  //   final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
  // 
  //   final weekdays = (itemMeta['weekdays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7];
  //   final userId = _selectedUser ?? 'all';
  //   
  //   final ratingSeries = computeUserRatingSeries(attendance, itemId, granularity: TimeGranularity.year, userId: userId, weekdays: weekdays);
  //   final currentRating = ratingSeries.isNotEmpty ? ratingSeries.last.rating : 0.0;
  //   
  //   final historyBars = computeUserHistory(attendance, itemId, granularity: TimeGranularity.month, userId: userId, weekdays: weekdays);
  //   final recentHistory = historyBars.length > 6 ? historyBars.sublist(historyBars.length - 6) : historyBars;
  //   final historyData = recentHistory.map((h) => [
  //     DateFormat('MMM yyyy').format(h.start),
  //     h.present.toString(),
  //     h.onLeave.toString(),
  //   ]).toList();
  // 
  //   final runs = computeBestUserSeries(attendance, itemId, userId: userId, weekdays: weekdays, limit: 5);
  //   final streaksData = runs.map((r) => {
  //     'start': DateFormat('yyyy-MM-dd').format(r.start),
  //     'end': DateFormat('yyyy-MM-dd').format(r.end),
  //     'length': r.length.toString(),
  //   }).toList();
  // 
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => PdfPreviewPage(
  //         title: 'Statistics_${itemName}_${userId}_$dateStr',
  //         data: const {}, 
  //         layout: StatisticsPdfLayout(
  //           itemName: '$itemName ($userId)',
  //           dateStr: dateStr,
  //           currentRating: '${(currentRating * 100).round()}%',
  //           totalRecords: '${normalizedDatesForItem(attendance, itemId, weekdays: weekdays).length}',
  //           historyData: historyData,
  //           streaksData: streaksData,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}