import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/tools/pdf_generator/catering_pdf_layout.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catering_organisation.dart';
import '../../state_management/catering_provider.dart';
import '../../state_management/user_list_provider.dart';
import 'widgets/catering_classic_view.dart';
import 'widgets/catering_modern_view.dart';

final List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];

class CateringPage extends ConsumerStatefulWidget {
  const CateringPage({super.key});

  @override
  ConsumerState<CateringPage> createState() => _CateringPageState();
}

class _CateringPageState extends ConsumerState<CateringPage> {
  bool _modernView = true;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = [
      translation(context: context, 'Monday'),
      translation(context: context, 'Tuesday'),
      translation(context: context, 'Wednesday'),
      translation(context: context, 'Thursday'),
      translation(context: context, 'Friday'),
      translation(context: context, 'Saturday'),
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
        final slotNamesAsync = ref.watch(cateringSlotNamesProvider);
        final uniformAsync = ref.watch(cateringUniformDaysProvider);
        return weekPlanAsync.when(
          data: (weekPlan) {
            final uniformDays = uniformAsync.asData?.value ?? List<bool>.filled(7, false);
            // Only show days with at least one user in any meal
            List<int> visibleDays = [];
            bool hasAnyUser = false;
            for (int day = 0; day < 7; day++) {
              bool hasUser = false;
              for (int meal = 0; meal < weekPlan[day].length; meal++) {
                if (weekPlan[day][meal].isNotEmpty) {
                  hasUser = true;
                  hasAnyUser = true;
                  break;
                }
              }
              if (hasUser) visibleDays.add(day);
            }
            // Sort visibleDays so today comes first
            final todayIndex = now.weekday - 1; // 0=Monday, 6=Sunday
            visibleDays.sort((a, b) {
              // Calculate distance from today (wrapping around the week)
              int distA = (a - todayIndex) % 7;
              int distB = (b - todayIndex) % 7;
              if (distA < 0) distA += 7;
              if (distB < 0) distB += 7;
              return distA.compareTo(distB);
            });
            return Scaffold(
              appBar: CustomAppBar(
                title: translation(context: context, 'Catering'),
                pdfLayout: CateringPdfLayout(),
                onGeneratePdf: () async {
                  final Map<String, List<Map<String, dynamic>>> pdfData = {};
                  for (int day = 0; day < 7; day++) {
                    final dayName = days[day];
                    final entries = weekPlan[day];
                    final hasAssignments = entries.any((meal) => meal.isNotEmpty);
                    if (!hasAssignments) {
                      continue;
                    }

                    final isUniformDay = day < uniformDays.length ? uniformDays[day] : false;

                    if (isUniformDay) {
                      final uniqueAssignees = entries
                          .expand((meal) => meal)
                          .where((name) => name.trim().isNotEmpty)
                          .toSet()
                          .toList();
                      if (uniqueAssignees.isEmpty) {
                        continue;
                      }
                      pdfData[dayName] = [
                        {
                          'Assignees': uniqueAssignees.join(', '),
                        }
                      ];
                    } else {
                      final dayEntries = <Map<String, dynamic>>[];
                      for (int meal = 0; meal < entries.length; meal++) {
                        if (entries[meal].isEmpty || meal >= mealsTranslated.length) {
                          continue;
                        }
                        dayEntries.add({
                          'Meal': mealsTranslated[meal],
                          'Assignees': entries[meal].join(', '),
                        });
                      }
                      if (dayEntries.isNotEmpty) {
                        pdfData[dayName] = dayEntries;
                      }
                    }
                  }
                  return pdfData;
                },
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      tooltip: _modernView
                          ? translation(context: context, 'Switch to classic view')
                          : translation(context: context, 'Switch to modern view'),
                      icon: Icon(_modernView ? Icons.view_list : Icons.auto_awesome),
                      onPressed: () => setState(() => _modernView = !_modernView),
                    ),
                  ),
                ],
              ),
              body: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: hasAnyUser
                      ? (_modernView
                          ? CateringModernView(
                              weekPlan: weekPlan,
                              uniformDays: uniformDays,
                              visibleDays: visibleDays,
                              monday: monday,
                              dayNames: days,
                              meals: meals,
                              mealsTranslated: mealsTranslated,
                              slotNames: slotNamesAsync.asData?.value ?? {},
                            )
                          : CateringClassicView(
                              weekPlan: weekPlan,
                              uniformDays: uniformDays,
                              visibleDays: visibleDays,
                              monday: monday,
                              dayNames: days,
                              meals: meals,
                              mealsTranslated: mealsTranslated,
                              slotNames: slotNamesAsync.asData?.value ?? {},
                            ))
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
                                style: const TextStyle(
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
                                  style: const TextStyle(
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

