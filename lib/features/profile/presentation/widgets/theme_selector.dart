import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/theme/theme_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';

class ThemeSelector extends ConsumerWidget {
  final Color borderColor;
  const ThemeSelector({super.key, required this.borderColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).value;
    final themeOptions = [
      AppThemeMode.system,
      AppThemeMode.light,
      AppThemeMode.dark,
    ];
    final themeLabels = {
      AppThemeMode.system: translation(context: context, 'System'),
      AppThemeMode.light: translation(context: context, 'Light'),
      AppThemeMode.dark: translation(context: context, 'Dark'),
    };
    final selectedIndex = themeOptions.indexOf(themeMode ?? AppThemeMode.system);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
            translation(context: context, 'Theme'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: List.generate(themeOptions.length * 2 - 1, (j) {
                const double chipHeight = 38;
                if (j.isOdd) {
                  // Divider between chips
                  return Container(
                    width: 1.2,
                    height: chipHeight,
                    color: borderColor.withOpacity(0.18),
                  );
                }
                final i = j ~/ 2;
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(themeOptions[i]);
                    },
                    child: Container(
                      height: chipHeight,
                      decoration: BoxDecoration(
                        color: isSelected ? borderColor.withOpacity(0.15) : Colors.transparent,
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                bottomLeft: Radius.circular(32),
                              )
                            : i == themeOptions.length - 1
                                ? const BorderRadius.only(
                                    topRight: Radius.circular(32),
                                    bottomRight: Radius.circular(32),
                                  )
                                : BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_rounded, size: 18, color: borderColor),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            themeLabels[themeOptions[i]]!,
                            style: TextStyle(
                              color: isSelected ? borderColor : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}