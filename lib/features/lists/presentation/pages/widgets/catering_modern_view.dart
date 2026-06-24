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

  Color _getBadgeBgColor(BuildContext context, int mealIdx, bool isDark) {
    switch (mealIdx) {
      case 0: // Breakfast
        return Colors.orange.withValues(alpha: isDark ? 0.16 : 0.08);
      case 1: // Lunch
        return Colors.teal.withValues(alpha: isDark ? 0.16 : 0.08);
      case 2: // Dinner
        return Colors.indigo.withValues(alpha: isDark ? 0.16 : 0.08);
      default:
        return Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5);
    }
  }

  Color _getBadgeTextColor(BuildContext context, int mealIdx, bool isDark) {
    switch (mealIdx) {
      case 0: // Breakfast
        return isDark ? Colors.orangeAccent : Colors.orange[800]!;
      case 1: // Lunch
        return isDark ? Colors.tealAccent : Colors.teal[800]!;
      case 2: // Dinner
        return isDark ? Colors.indigoAccent : Colors.indigo[800]!;
      default:
        return Theme.of(context).colorScheme.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: visibleDays.length,
      padding: const EdgeInsets.fromLTRB(12, 96, 12, 96),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final dayIdx = visibleDays[idx];
        final date = monday.add(Duration(days: dayIdx));
        final isToday = DateTime.now().weekday - 1 == dayIdx;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isToday 
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isToday ? 2 : 1,
            ),
          ),
          color: theme.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day and Date Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayNames[dayIdx],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              translation(context: context, 'Today'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Meal Slots list
                if (uniformDays[dayIdx]) ...[
                  // Aggregated uniform view
                  _MealRow(
                    badge: translation(context: context, 'All meals'),
                    badgeBgColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    badgeTextColor: theme.colorScheme.onPrimaryContainer,
                    children: () {
                      final users = <String>{};
                      for (final slot in weekPlan[dayIdx]) {
                        for (final u in slot) {
                          if (u.trim().isNotEmpty) users.add(u);
                        }
                      }
                      return users.map((u) => CustomChip(
                        label: u,
                        backgroundColor: theme.colorScheme.surface,
                        textColor: theme.colorScheme.primary,
                      )).toList();
                    }(),
                  ),
                ] else ...[
                  // Single meals breakdown
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: weekPlan[dayIdx].length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    itemBuilder: (context, mealIdx) {
                      final assignees = weekPlan[dayIdx][mealIdx]
                          .where((u) => u.trim().isNotEmpty)
                          .toList();

                      if (assignees.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final badgeLabel = mealIdx < mealsTranslated.length
                          ? mealsTranslated[mealIdx]
                          : (slotNames['${dayIdx}_$mealIdx'] ?? '${translation(context: context, 'Assignment')} ${mealIdx + 1}');

                      return _MealRow(
                        badge: badgeLabel,
                        badgeBgColor: _getBadgeBgColor(context, mealIdx, isDark),
                        badgeTextColor: _getBadgeTextColor(context, mealIdx, isDark),
                        children: assignees.map((u) => CustomChip(
                          label: u,
                          backgroundColor: theme.colorScheme.surface,
                          textColor: theme.colorScheme.onSurface,
                        )).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealRow extends StatelessWidget {
  final String badge;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final List<Widget> children;

  const _MealRow({
    required this.badge,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}