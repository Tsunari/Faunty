import 'dart:ui';
import 'package:faunty/core/widgets/custom_chip.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';

class CateringModernView extends StatelessWidget {
  final List<List<List<String>>> weekPlan;
  final List<bool> uniformDays;
  final List<int> visibleDays;
  final DateTime monday;
  final List<String> dayNames;
  final List<String> meals;
  final List<String> mealsTranslated;
  final Map<String, String> slotNames;

  const CateringModernView({
    super.key,
    required this.weekPlan,
    required this.uniformDays,
    required this.visibleDays,
    required this.monday,
    required this.dayNames,
    required this.meals,
    required this.mealsTranslated,
    required this.slotNames,
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
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          color: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08),
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
                    // aggregate across all slots for the day
                    _CompactSection(
                      badge: translation(context: context, 'All meals'),
                      children: () {
                        final users = <String>{};
                        for (final slot in weekPlan[dayIdx]) {
                          for (final u in slot) users.add(u);
                        }
                        return users.map((u) => CustomChip(label: u)).toList();
                      }(),
                    )
                  else ...[
                    for (int mealIdx = 0; mealIdx < weekPlan[dayIdx].length; mealIdx++)
                      if (weekPlan[dayIdx][mealIdx].isNotEmpty)
                        _CompactSection(
                          badge: mealIdx < mealsTranslated.length
                              ? mealsTranslated[mealIdx]
                              : (slotNames['${dayIdx}_$mealIdx'] ?? '${translation(context: context, 'Assignment')} ${mealIdx + 1}'),
                          children: weekPlan[dayIdx][mealIdx]
                              .map((u) => CustomChip(label: u))
                              .toList(),
                        )
                  ],
                ],
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