import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tools/local_storage_helper.dart';

// Enum for theme modes
enum AppThemeMode { system, light, dark }

AppThemeMode themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    default:
      return AppThemeMode.system;
  }
}

String themeModeToString(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return 'light';
    case AppThemeMode.dark:
      return 'dark';
    case AppThemeMode.system:
      return 'system';
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AsyncValue<AppThemeMode>>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<AsyncValue<AppThemeMode>> {
  ThemeNotifier() : super(const AsyncValue.loading()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final modeStr = await LocalStorageHelper.getThemeMode();
      if (modeStr == null) {
        state = AsyncValue.data(AppThemeMode.dark);
      } else {
        state = AsyncValue.data(themeModeFromString(modeStr));
      }
    } catch (e) {
      state = AsyncValue.data(AppThemeMode.dark);
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = AsyncValue.data(mode);
    await LocalStorageHelper.setThemeMode(themeModeToString(mode));
  }
}
