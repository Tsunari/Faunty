import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/i18n/strings.g.dart';
import 'package:faunty/core/i18n/language_provider.dart';

class LanguageDropdown extends ConsumerWidget {
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  const LanguageDropdown({
    super.key,
    this.borderColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final locales = AppLocale.values;
    final localeNames = {
      AppLocale.en: 'English',
      AppLocale.de: 'Deutsch',
      AppLocale.tr: 'Türkçe',
      AppLocale.ru: 'Русский',
    };
    final selectedCode = ref.watch(languageProvider);
    final selectedLocale = locales.firstWhere(
      (loc) => loc.languageTag == selectedCode,
      orElse: () => AppLocale.en,
    );
    final selectedName = localeNames[selectedLocale] ?? selectedLocale.languageTag;

    return PopupMenuButton<AppLocale>(
      onSelected: (newLocale) {
        LocaleSettings.setLocale(newLocale);
        ref.read(languageProvider.notifier).setLanguage(newLocale.languageTag);
      },
      itemBuilder: (context) => locales.map((loc) => PopupMenuItem<AppLocale>(
        value: loc,
        child: Row(
          children: [
            Icon(Icons.translate, size: 16, color: primaryColor),
            const SizedBox(width: 12),
            Text(localeNames[loc] ?? loc.languageTag),
          ],
        ),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? primaryColor.withOpacity(0.12)),
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: primaryColor),
          ],
        ),
      ),
    );
  }
}