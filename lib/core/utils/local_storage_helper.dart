import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  static const String themePresetKey = 'theme_preset_index';

  static Future<void> setThemePresetIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(themePresetKey, index);
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<int?> getThemePresetIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(themePresetKey);
    } catch (e) {
      // Ignore errors
      return null;
    }
  }
  static const String languageCodeKey = 'language_code';

  static Future<void> setLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageCodeKey, code);
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<String?> getLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(languageCodeKey);
    } catch (e) {
      // Ignore errors
      return null;
    }
  }
  static const String themeModeKey = 'theme_mode';

  static Future<void> setThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeModeKey, mode);
    } catch (e) {
      // Ignore errors (e.g., MissingPluginException)
    }
  }

  static Future<String?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(themeModeKey);
    } catch (e) {
      // Ignore errors (e.g., MissingPluginException)
      return null;
    }
  }
}
