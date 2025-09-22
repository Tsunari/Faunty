import 'package:faunty/components/custom_chip.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';

class CateringClassicView extends StatelessWidget {
  final List<List<List<String>>> weekPlan;
  final List<bool> uniformDays;
  final List<int> visibleDays;
  final DateTime monday;
  final List<String> dayNames;
  final List<String> meals;
  final List<String> mealsTranslated;

  const CateringClassicView({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: visibleDays.length,
      itemBuilder: (context, idx) {
        final dayIdx = visibleDays[idx];
        final date = monday.add(Duration(days: dayIdx));
        return Card(
          color: isDark ? Colors.grey[850] : null,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${dayNames[dayIdx]}, ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                if (uniformDays[dayIdx])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            translation(context: context, 'All meals'),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: weekPlan[dayIdx][0]
                                .map((user) => CustomChip(label: user))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(meals.length, (mealIdx) =>
                      weekPlan[dayIdx][mealIdx].isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      mealsTranslated[mealIdx],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: weekPlan[dayIdx][mealIdx]
                                          .map((user) => CustomChip(label: user))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
