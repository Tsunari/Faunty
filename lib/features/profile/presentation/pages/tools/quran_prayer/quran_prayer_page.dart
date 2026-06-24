import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/prayer_habit_section.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/quran_prayer_models.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/prayer_storage.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/quran_progress_section.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/section_header.dart';

class QuranPrayerPage extends StatefulWidget {
  const QuranPrayerPage({super.key});

  @override
  State<QuranPrayerPage> createState() => _QuranPrayerPageState();
}

class _QuranPrayerPageState extends State<QuranPrayerPage> {
  static const int _totalJuz = 30;
  static const int _totalPages = 604;
  static const int _listDays = 14;
  static const List<int> _juzStartPages = [
    1,
    21,
    41,
    61,
    81,
    101,
    121,
    141,
    161,
    181,
    201,
    221,
    241,
    261,
    281,
    301,
    321,
    341,
    361,
    381,
    401,
    421,
    441,
    461,
    481,
    501,
    521,
    541,
    561,
    581,
  ];

  final List<String> _prayerNames = const [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  final PrayerLocalStorage _storage = PrayerLocalStorage();

  bool _isLoading = true;
  int _currentPage = 1;
  Map<String, QuranProgressProfile> _quranProfiles = {};
  String _activeQuranProfileId = '';
  PrayerTrackingMode _trackingMode = PrayerTrackingMode.missedOnly;
  PrayerStatsScope _statsScope = PrayerStatsScope.weekly;
  Map<String, Map<String, bool>> _entries = {};

  int get _currentJuz => _juzFromPage(_currentPage);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = await _storage.load();
    if (!mounted) return;

    setState(() {
      final fallbackPage = state.currentPage ?? 1;
      _quranProfiles = state.quranProfiles;
      _activeQuranProfileId = state.activeQuranProfileId ?? '';
      _ensureDefaultProfile(fallbackPage);
      _currentPage = _activeProfile.currentPage;
      _trackingMode = state.trackingMode;
      _entries = state.entries;
      _isLoading = false;
    });
  }

  void _ensureDefaultProfile(int fallbackPage) {
    if (_quranProfiles.isNotEmpty && _activeQuranProfileId.isNotEmpty) {
      if (_quranProfiles.containsKey(_activeQuranProfileId)) {
        return;
      }
    }

    if (_quranProfiles.isEmpty) {
      final profile = QuranProgressProfile(
        id: 'default',
        name: translation(context: context, 'Default'),
        currentPage: fallbackPage,
      );
      _quranProfiles = {'default': profile};
    }

    _activeQuranProfileId = _quranProfiles.keys.first;
    _storage.saveQuranProfiles(_quranProfiles);
    _storage.saveActiveQuranProfileId(_activeQuranProfileId);
  }

  QuranProgressProfile get _activeProfile {
    return _quranProfiles[_activeQuranProfileId] ?? _quranProfiles.values.first;
  }

  List<QuranProgressProfile> get _orderedProfiles {
    final profiles = _quranProfiles.values.toList();
    profiles.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return profiles;
  }

  int _juzFromPage(int page) {
    var juz = 1;
    for (var i = 0; i < _juzStartPages.length; i++) {
      if (page >= _juzStartPages[i]) {
        juz = i + 1;
      } else {
        break;
      }
    }
    return juz;
  }

  int _pageFromJuz(int juz) {
    final index = juz.clamp(1, _totalJuz) - 1;
    return _juzStartPages[index];
  }

  int _juzStartPage(int juz) {
    final index = juz.clamp(1, _totalJuz) - 1;
    return _juzStartPages[index];
  }

  int _juzEndPage(int juz) {
    if (juz >= _totalJuz) {
      return _totalPages;
    }
    return _juzStartPages[juz] - 1;
  }

  void _setPage(int page) {
    final nextPage = page.clamp(1, _totalPages);
    setState(() {
      _currentPage = nextPage;
      final profile = _activeProfile.copyWith(currentPage: nextPage);
      _quranProfiles[_activeProfile.id] = profile;
    });
    _storage.saveQuranProfiles(_quranProfiles);
  }

  void _setJuz(int juz) {
    final page = _pageFromJuz(juz.clamp(1, _totalJuz));
    setState(() {
      _currentPage = page;
      final profile = _activeProfile.copyWith(currentPage: page);
      _quranProfiles[_activeProfile.id] = profile;
    });
    _storage.saveQuranProfiles(_quranProfiles);
  }

  void _selectQuranProfile(String id) {
    if (!_quranProfiles.containsKey(id)) return;
    setState(() {
      _activeQuranProfileId = id;
      _currentPage = _quranProfiles[id]?.currentPage ?? _currentPage;
    });
    _storage.saveActiveQuranProfileId(id);
  }

  Future<void> _addQuranProfile() async {
    final name = await _showProfileNameDialog(
      title: translation(context: context, 'Add progress'),
      initialValue: '',
    );
    if (name == null || name.trim().isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = QuranProgressProfile(
      id: id,
      name: name.trim(),
      currentPage: _currentPage,
    );

    setState(() {
      _quranProfiles[id] = profile;
      _activeQuranProfileId = id;
    });

    _storage.saveQuranProfiles(_quranProfiles);
    _storage.saveActiveQuranProfileId(id);
  }

  Future<void> _renameQuranProfile(String id) async {
    final profile = _quranProfiles[id];
    if (profile == null) return;

    final name = await _showProfileNameDialog(
      title: translation(context: context, 'Rename progress'),
      initialValue: profile.name,
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() {
      _quranProfiles[id] = profile.copyWith(name: name.trim());
    });

    _storage.saveQuranProfiles(_quranProfiles);
  }

  void _deleteQuranProfile(String id) {
    if (_quranProfiles.length <= 1) return;
    if (!_quranProfiles.containsKey(id)) return;

    setState(() {
      _quranProfiles.remove(id);
      if (_activeQuranProfileId == id) {
        _activeQuranProfileId = _quranProfiles.keys.first;
        _currentPage =
            _quranProfiles[_activeQuranProfileId]?.currentPage ?? _currentPage;
      }
    });

    _storage.saveQuranProfiles(_quranProfiles);
    _storage.saveActiveQuranProfileId(_activeQuranProfileId);
  }

  Future<String?> _showProfileNameDialog({
    required String title,
    required String initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: translation(context: context, 'Name'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context: context, 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(translation(context: context, 'Save')),
            ),
          ],
        );
      },
    );
  }

  void _setTrackingMode(PrayerTrackingMode mode) {
    setState(() {
      _trackingMode = mode;
    });
    _storage.saveTrackingMode(mode);
  }

  void _setStatsScope(PrayerStatsScope scope) {
    setState(() {
      _statsScope = scope;
    });
  }

  Map<String, bool> _defaultPrayerMap() {
    final defaultCompleted = _trackingMode == PrayerTrackingMode.missedOnly;
    return {for (final name in _prayerNames) name: defaultCompleted};
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, bool> _getPrayerMap(DateTime date) {
    final key = _dateKey(date);
    final existing = _entries[key];
    if (existing == null) {
      return _defaultPrayerMap();
    }
    return Map<String, bool>.from(existing);
  }

  PrayerDayData _buildDayData(DateTime date) {
    return PrayerDayData(date: date, prayers: _getPrayerMap(date));
  }

  void _togglePrayer(DateTime date, String prayerName, bool isChecked) {
    final key = _dateKey(date);
    final current = Map<String, bool>.from(
      _entries[key] ?? _defaultPrayerMap(),
    );
    final completed = _trackingMode == PrayerTrackingMode.missedOnly
        ? !isChecked
        : isChecked;
    current[prayerName] = completed;

    setState(() {
      _entries[key] = current;
    });

    _storage.saveEntries(_entries);
  }

  List<PrayerDayData> _buildDisplayDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(
      _listDays,
      (index) => _buildDayData(today.subtract(Duration(days: index))),
    );
  }

  int _statsDaysForScope(PrayerStatsScope scope) {
    switch (scope) {
      case PrayerStatsScope.weekly:
        return 7;
      case PrayerStatsScope.monthly:
        return 30;
      case PrayerStatsScope.yearly:
        return 365;
    }
  }

  List<PrayerDayData> _buildStatsDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = _statsDaysForScope(_statsScope);

    return List.generate(
      totalDays,
      (index) => _buildDayData(today.subtract(Duration(days: index))),
    );
  }

  PrayerStatsSummary _buildStatsSummary(List<PrayerDayData> days) {
    var completed = 0;
    var total = 0;
    var daysCompleted = 0;

    for (final day in days) {
      completed += day.completedCount;
      total += day.prayers.length;
      if (day.isComplete) {
        daysCompleted++;
      }
    }

    var streak = 0;
    for (final day in days) {
      if (day.isComplete) {
        streak++;
      } else {
        break;
      }
    }

    return PrayerStatsSummary(
      completed: completed,
      total: total,
      daysCompleted: daysCompleted,
      currentStreak: streak,
    );
  }

  List<PrayerChartBucket> _buildChartBuckets(
    BuildContext context,
    List<PrayerDayData> days,
  ) {
    switch (_statsScope) {
      case PrayerStatsScope.weekly:
        return days
            .take(7)
            .map(
              (day) => PrayerChartBucket(
                label: _weekdayLabel(context, day.date),
                ratio: day.completionRatio,
              ),
            )
            .toList();
      case PrayerStatsScope.monthly:
        final buckets = <PrayerChartBucket>[];
        final weeks = [
          days.take(7).toList(),
          days.skip(7).take(7).toList(),
          days.skip(14).take(7).toList(),
          days.skip(21).take(9).toList(),
        ];
        for (var i = 0; i < weeks.length; i++) {
          final ratio = _averageRatio(weeks[i]);
          buckets.add(PrayerChartBucket(label: '${i + 1}', ratio: ratio));
        }
        return buckets;
      case PrayerStatsScope.yearly:
        final locale = Localizations.localeOf(context).toString();
        final formatter = DateFormat.MMM(locale);
        final now = DateTime.now();
        final buckets = <PrayerChartBucket>[];

        for (var i = 0; i < 12; i++) {
          final monthDate = DateTime(now.year, now.month - i, 1);
          final monthDays = days.where(
            (day) =>
                day.date.year == monthDate.year &&
                day.date.month == monthDate.month,
          );
          final ratio = _averageRatio(monthDays.toList());
          buckets.add(
            PrayerChartBucket(label: formatter.format(monthDate), ratio: ratio),
          );
        }

        return buckets.reversed.toList();
    }
  }

  double _averageRatio(List<PrayerDayData> days) {
    if (days.isEmpty) return 0;
    final total = days.fold<double>(0, (sum, day) => sum + day.completionRatio);
    return total / days.length;
  }

  String _weekdayLabel(BuildContext context, DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return translation(context: context, 'Mo');
      case DateTime.tuesday:
        return translation(context: context, 'Tue');
      case DateTime.wednesday:
        return translation(context: context, 'Wed');
      case DateTime.thursday:
        return translation(context: context, 'Thu');
      case DateTime.friday:
        return translation(context: context, 'Fr');
      case DateTime.saturday:
        return translation(context: context, 'Sat');
      case DateTime.sunday:
        return translation(context: context, 'Sun');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDays = _buildDisplayDays();
    final statsDays = _buildStatsDays();
    final statsSummary = _buildStatsSummary(statsDays);
    final chartBuckets = _buildChartBuckets(context, statsDays);
    final completionLabel = _completionLabel(context, _statsScope);

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Quran and Prayers'),
        useModern: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionHeader(
                  title: translation(context: context, 'Quran Progress'),
                ),
                const SizedBox(height: 12),
                QuranProgressSection(
                  currentJuz: _currentJuz,
                  currentPage: _currentPage,
                  totalJuz: _totalJuz,
                  totalPages: _totalPages,
                  juzStartPage: _juzStartPage(_currentJuz),
                  juzEndPage: _juzEndPage(_currentJuz),
                  profiles: _orderedProfiles,
                  activeProfileId: _activeQuranProfileId,
                  onSelectProfile: _selectQuranProfile,
                  onAddProfile: _addQuranProfile,
                  onRenameProfile: _renameQuranProfile,
                  onDeleteProfile: _deleteQuranProfile,
                  accentColor: theme.colorScheme.primary,
                  onJuzChanged: _setJuz,
                  onPageChanged: _setPage,
                  subtitle: translation(
                    context: context,
                    'Juz and page are synced',
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: translation(context: context, 'Prayer Habit Tracker'),
                ),
                const SizedBox(height: 12),
                PrayerHabitSection(
                  prayerNames: _prayerNames,
                  displayDays: displayDays,
                  trackingMode: _trackingMode,
                  statsScope: _statsScope,
                  statsSummary: statsSummary,
                  chartBuckets: chartBuckets,
                  completionLabel: completionLabel,
                  totalDays: statsDays.length,
                  onModeChanged: _setTrackingMode,
                  onScopeChanged: _setStatsScope,
                  onTogglePrayer: _togglePrayer,
                  weekdayLabelBuilder: (date) => _weekdayLabel(context, date),
                ),
              ],
            ),
    );
  }

  String _completionLabel(BuildContext context, PrayerStatsScope scope) {
    switch (scope) {
      case PrayerStatsScope.weekly:
        return translation(context: context, 'Weekly completion');
      case PrayerStatsScope.monthly:
        return translation(context: context, 'Monthly completion');
      case PrayerStatsScope.yearly:
        return translation(context: context, 'Yearly completion');
    }
  }
}