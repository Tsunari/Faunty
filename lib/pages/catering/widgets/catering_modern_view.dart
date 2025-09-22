import 'dart:ui';
import 'package:faunty/components/custom_chip.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';

class CateringModernView extends StatelessWidget {
  final List<List<List<String>>> weekPlan;
  final List<bool> uniformDays;
  final List<int> visibleDays;
  final DateTime monday;
  final List<String> dayNames;
  final List<String> meals;
  final List<String> mealsTranslated;

  const CateringModernView({
    super.key,
    required this.weekPlan,
    required this.uniformDays,
    required this.visibleDays,
    required this.monday,
    required this.dayNames,
    required this.meals,
    required this.mealsTranslated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: visibleDays.length,
      padding: const EdgeInsets.only(bottom: 12),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, idx) {
        final dayIdx = visibleDays[idx];
        final date = monday.add(Duration(days: dayIdx));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayNames[dayIdx],
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(isDark ? 0.16 : 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (uniformDays[dayIdx])
                        _CompactSection(
                          badge: translation(context: context, 'All meals'),
                          children: weekPlan[dayIdx][0].map((u) => CustomChip(label: u)).toList(),
                        )
                      else ...[
                        for (int mealIdx = 0; mealIdx < meals.length; mealIdx++)
                          if (weekPlan[dayIdx][mealIdx].isNotEmpty)
                            _CompactSection(
                              badge: mealsTranslated[mealIdx],
                              children: weekPlan[dayIdx][mealIdx]
                                  .map((u) => CustomChip(label: u))
                                  .toList(),
                            )
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactSection extends StatelessWidget {
  final String badge;
  final List<Widget> children;
  const _CompactSection({required this.badge, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
