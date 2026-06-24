import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/utils/local_storage_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:faunty/core/i18n/strings.g.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final code = await LocalStorageHelper.getLanguageCode();
    if (code != null) {
      state = code;
      _setAppLocale(code);
    } else {
      // Use device locale if no persisted value
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      state = deviceLocale;
      _setAppLocale(deviceLocale);
    }
  }

  void _setAppLocale(String code) {
    // Set the app locale using Slang
    final locale = AppLocale.values.firstWhere(
      (loc) => loc.languageTag == code,
      orElse: () => AppLocale.en,
    );
    LocaleSettings.setLocale(locale);
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await LocalStorageHelper.setLanguageCode(code);
    _setAppLocale(code);
  }
}