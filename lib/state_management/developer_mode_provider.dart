import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperModeNotifier extends StateNotifier<bool> {
  DeveloperModeNotifier() : super(kDebugMode) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('developer_mode_enabled') ?? kDebugMode;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('developer_mode_enabled', value);
  }
}

final developerModeProvider =
    StateNotifierProvider<DeveloperModeNotifier, bool>((ref) {
      return DeveloperModeNotifier();
    });
