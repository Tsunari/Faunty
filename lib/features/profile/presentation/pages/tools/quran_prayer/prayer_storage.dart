import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faunty/features/profile/presentation/pages/tools/quran_prayer/quran_prayer_models.dart';

class PrayerStorageState {
  final int? currentPage;
  final PrayerTrackingMode trackingMode;
  final Map<String, Map<String, bool>> entries;
  final Map<String, QuranProgressProfile> quranProfiles;
  final String? activeQuranProfileId;

  PrayerStorageState({
    required this.currentPage,
    required this.trackingMode,
    required this.entries,
    required this.quranProfiles,
    required this.activeQuranProfileId,
  });
}

class PrayerLocalStorage {
  static const String _keyCurrentPage = 'quran_prayer_current_page';
  static const String _keyMode = 'quran_prayer_tracking_mode';
  static const String _keyEntries = 'quran_prayer_entries';
  static const String _keyQuranProfiles = 'quran_prayer_profiles';
  static const String _keyQuranActiveProfile = 'quran_prayer_active_profile';

  Future<PrayerStorageState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPage = prefs.getInt(_keyCurrentPage);
    final modeValue = prefs.getString(_keyMode);
    final trackingMode = _modeFromString(modeValue);
    final entries = _decodeEntries(prefs.getString(_keyEntries));
    final profiles = _decodeProfiles(prefs.getString(_keyQuranProfiles));
    final activeProfileId = prefs.getString(_keyQuranActiveProfile);

    return PrayerStorageState(
      currentPage: currentPage,
      trackingMode: trackingMode,
      entries: entries,
      quranProfiles: profiles,
      activeQuranProfileId: activeProfileId,
    );
  }

  Future<void> saveCurrentPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentPage, page);
  }

  Future<void> saveTrackingMode(PrayerTrackingMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, _modeToString(mode));
  }

  Future<void> saveEntries(Map<String, Map<String, bool>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEntries, jsonEncode(entries));
  }

  Future<void> saveQuranProfiles(
    Map<String, QuranProgressProfile> profiles,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranProfiles, _encodeProfiles(profiles));
  }

  Future<void> saveActiveQuranProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranActiveProfile, id);
  }

  String _modeToString(PrayerTrackingMode mode) {
    switch (mode) {
      case PrayerTrackingMode.missedOnly:
        return 'missed';
      case PrayerTrackingMode.manual:
        return 'manual';
    }
  }

  PrayerTrackingMode _modeFromString(String? value) {
    switch (value) {
      case 'manual':
        return PrayerTrackingMode.manual;
      case 'missed':
      default:
        return PrayerTrackingMode.missedOnly;
    }
  }

  Map<String, Map<String, bool>> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};

      return decoded.map((key, value) {
        if (value is! Map<String, dynamic>) {
          return MapEntry(key, <String, bool>{});
        }

        final map = value.map(
          (prayer, completed) => MapEntry(prayer, completed == true),
        );

        return MapEntry(key, map);
      });
    } catch (_) {
      return {};
    }
  }

  String _encodeProfiles(Map<String, QuranProgressProfile> profiles) {
    final data = profiles.map(
      (key, value) =>
          MapEntry(key, {'name': value.name, 'currentPage': value.currentPage}),
    );
    return jsonEncode(data);
  }

  Map<String, QuranProgressProfile> _decodeProfiles(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};

      return decoded.map((key, value) {
        if (value is! Map<String, dynamic>) {
          return MapEntry(
            key,
            QuranProgressProfile(id: key, name: key, currentPage: 1),
          );
        }

        final name = value['name']?.toString() ?? key;
        final page = value['currentPage'] is int
            ? value['currentPage'] as int
            : int.tryParse(value['currentPage']?.toString() ?? '') ?? 1;

        return MapEntry(
          key,
          QuranProgressProfile(id: key, name: name, currentPage: page),
        );
      });
    } catch (_) {
      return {};
    }
  }
}