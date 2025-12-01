import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../state_management/user_provider.dart';
import '../../../state_management/attendance_provider.dart';
import '../../../tools/translation_helper.dart';
import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/pages/pdf/pdf_preview_page.dart';
import 'package:faunty/tools/pdf_generator/statistics_pdf_layout.dart';

import 'statistics_widgets.dart';
import 'stats_utils.dart';

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

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Statistics'),
        useModern: false,
        actions: [
          if (items.isNotEmpty) ...[
            // TODO: Add PDF export
            // IconButton(
            //   icon: const Icon(Icons.picture_as_pdf),
            //   onPressed: () => _generatePdf(context, attendance, items.firstWhere((e) => e['id'] == _selectedItem, orElse: () => items.first), user.placeId),
            // ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _captureAndShare(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String>(
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
            ),
          ],
        ],
      ),
      body: _selectedItem.isEmpty || items.isEmpty
          ? Center(child: Text(translation(context: context, 'Create a tracking item to see statistics.')))
          : Padding(
            padding: const EdgeInsets.only(top: 10.0),
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

  Future<void> _generatePdf(BuildContext context, Map<String, dynamic> attendance, Map<String, dynamic> itemMeta, String placeId) async {
    final itemName = itemMeta['name'] as String? ?? 'Unknown';
    final itemId = itemMeta['id'] as String;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final weekdays = (itemMeta['weekdays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7];
    final userId = _selectedUser ?? 'all';
    
    final ratingSeries = computeUserRatingSeries(attendance, itemId, granularity: TimeGranularity.year, userId: userId, weekdays: weekdays);
    final currentRating = ratingSeries.isNotEmpty ? ratingSeries.last.rating : 0.0;
    
    final historyBars = computeUserHistory(attendance, itemId, granularity: TimeGranularity.month, userId: userId, weekdays: weekdays);
    final recentHistory = historyBars.length > 6 ? historyBars.sublist(historyBars.length - 6) : historyBars;
    final historyData = recentHistory.map((h) => [
      DateFormat('MMM yyyy').format(h.start),
      h.present.toString(),
      h.onLeave.toString(),
    ]).toList();

    final runs = computeBestUserSeries(attendance, itemId, userId: userId, weekdays: weekdays, limit: 5);
    final streaksData = runs.map((r) => {
      'start': DateFormat('yyyy-MM-dd').format(r.start),
      'end': DateFormat('yyyy-MM-dd').format(r.end),
      'length': r.length.toString(),
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfPreviewPage(
          title: 'Statistics_${itemName}_${userId}_$dateStr',
          data: const {}, 
          layout: StatisticsPdfLayout(
            itemName: '$itemName ($userId)',
            dateStr: dateStr,
            currentRating: '${(currentRating * 100).round()}%',
            totalRecords: '${normalizedDatesForItem(attendance, itemId, weekdays: weekdays).length}',
            historyData: historyData,
            streaksData: streaksData,
          ),
        ),
      ),
    );
  }
}
