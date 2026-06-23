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
    final primaryColor = Theme.of(context).colorScheme.primary;
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? primaryColor.withOpacity(0.5)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButton<AppLocale>(
        value: selectedLocale,
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        underline: SizedBox(),
        borderRadius: BorderRadius.circular(borderRadius),
        style: Theme.of(context).textTheme.bodyMedium,
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: locales.map((loc) {
          return DropdownMenuItem<AppLocale>(
            value: loc,
            child: Row(
              children: [
                Icon(Icons.flag, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(localeNames[loc] ?? loc.languageTag),
              ],
            ),
          );
        }).toList(),
        onChanged: (newLocale) {
          if (newLocale != null) {
            LocaleSettings.setLocale(newLocale);
            ref.read(languageProvider.notifier).setLanguage(newLocale.languageTag);
          }
        },
      ),
    );
  }
}