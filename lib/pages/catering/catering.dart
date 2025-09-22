import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/components/custom_chip.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catering_organisation.dart';
import '../../state_management/catering_provider.dart';
import '../../state_management/user_list_provider.dart';

final List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];

class CateringPage extends ConsumerStatefulWidget {
  const CateringPage({super.key});

  @override
  ConsumerState<CateringPage> createState() => _CateringPageState();
}

class _CateringPageState extends ConsumerState<CateringPage> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = [
      translation(context: context, 'Monday'), translation(context: context, 'Tuesday'),
      translation(context: context, 'Wednesday'), translation(context: context, 'Thursday'),
      translation(context: context, 'Friday'), translation(context: context, 'Saturday'),
      translation(context: context, 'Sunday')
    ];
    final mealsTranslated = [
      translation(context: context, 'Breakfast'),
      translation(context: context, 'Lunch'),
      translation(context: context, 'Dinner'),
    ];
    final roles = [UserRole.baskan, UserRole.talebe].map((r) => r.name).join(',');
    final usersAsync = ref.watch(usersByRolesAndPlaceProvider(roles));
    return usersAsync.when(
      data: (userList) {
        final userNames = userList.map((u) => '${u.firstName} ${u.lastName}').toList();
        final weekPlanAsync = ref.watch(cateringWeekPlanProvider);
        final uniformAsync = ref.watch(cateringUniformDaysProvider);
        return weekPlanAsync.when(
          data: (weekPlan) {
            final uniformDays = uniformAsync.asData?.value ?? List<bool>.filled(7, false);
            // Only show days with at least one user in any meal
            List<int> visibleDays = [];
            bool hasAnyUser = false;
            for (int day = 0; day < 7; day++) {
              bool hasUser = false;
              for (int meal = 0; meal < meals.length; meal++) {
                if (weekPlan[day][meal].isNotEmpty) {
                  hasUser = true;
                  hasAnyUser = true;
                  break;
                }
              }
              if (hasUser) visibleDays.add(day);
            }
            return Scaffold(
              appBar: CustomAppBar(
                title: translation(context: context, 'Catering'),
              ),
              body: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: hasAnyUser
                      ? ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
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
                                        '${days[dayIdx]}, ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16
                                        ),
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
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: weekPlan[dayIdx][0].map((user) => CustomChip(
                                                      label: user,
                                                    )).toList(),
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
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w500
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        children: weekPlan[dayIdx][mealIdx].map((user) => CustomChip(
                                                              label: user,
                                                            )).toList(),
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
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_food_beverage, size: 64, color: notFoundIconColor(context)),
                              const SizedBox(height: 24),
                              Text(
                                translation(context: context, 'No catering assignments yet!'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              RoleGate(
                                minRole: UserRole.baskan,
                                child: Text(
                                  translation(context: context, 'Tap the edit button below to assign users to meals for the week.'),
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              floatingActionButton: RoleGate(
                minRole: UserRole.baskan,
                child: FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CateringOrganisationPage(
                          weekPlan: weekPlan,
                          users: userNames,
                          meals: meals,
                          mealsTranslated: mealsTranslated,
                        ),
                      ),
                    );
                    if (result != null && result is List<List<List<String>>>) {
                      // Save to Firestore
                      final service = ref.read(cateringFirestoreServiceProvider);
                      await service.setWeekPlan(result);
                    }
                  },
                  tooltip: translation(context: context, 'Edit'),
                  child: const Icon(Icons.edit),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading catering data: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading users: $e')),
    );
  }
}
