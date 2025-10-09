import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/catering_provider.dart';
import '../../components/custom_confirm_dialog.dart';

class CateringOrganisationPage extends ConsumerStatefulWidget {
  final List<List<List<String>>> weekPlan;
  final List<String> users;
  final List<String> meals;
  final List<String> mealsTranslated;

  const CateringOrganisationPage({super.key, required this.weekPlan, required this.users, required this.meals, required this.mealsTranslated});

  @override
  ConsumerState<CateringOrganisationPage> createState() => _CateringOrganisationPageState();
}

class _CateringOrganisationPageState extends ConsumerState<CateringOrganisationPage> {
  List<List<List<String>>>? localWeekPlan;
  bool isSaving = false;
  List<bool>? uniformDays;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final weekPlanAsync = ref.watch(cateringWeekPlanProvider);
    if (weekPlanAsync is AsyncData<List<List<List<String>>>>) {
      final firestorePlan = weekPlanAsync.value;
      if (localWeekPlan == null || !_deepEquals(localWeekPlan!, firestorePlan)) {
        // Only update if different (prevents overwriting local edits)
        localWeekPlan = firestorePlan.map((day) => day.map((meal) => List<String>.from(meal)).toList()).toList();
      }
    }
    final uniformAsync = ref.watch(cateringUniformDaysProvider);
    if (uniformAsync is AsyncData<List<bool>>) {
      final firestoreUniform = uniformAsync.value;
      if (uniformDays == null || !_boolListEquals(uniformDays!, firestoreUniform)) {
        uniformDays = List<bool>.from(firestoreUniform);
      }
    }
  }

  bool _deepEquals(List<List<List<String>>> a, List<List<List<String>>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (int j = 0; j < a[i].length; j++) {
        if (a[i][j].length != b[i][j].length) return false;
        for (int k = 0; k < a[i][j].length; k++) {
          if (a[i][j][k] != b[i][j][k]) return false;
        }
      }
    }
    return true;
  }
  
  bool _boolListEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String getWeekday(int weekday, bool translated) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysTranslated = [
      translation(context: context, 'Montag'),
      translation(context: context, 'Dienstag'),
      translation(context: context, 'Mittwoch'),
      translation(context: context, 'Donnerstag'),
      translation(context: context, 'Freitag'),
      translation(context: context, 'Samstag'),
      translation(context: context, 'Sonntag')
    ];
    return translated ? daysTranslated[weekday % 7] : days[weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (localWeekPlan == null || uniformDays == null) {
      // Show loading until Firestore data is available
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catering Organisation'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [],
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 500,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => true,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, dayIdx) {
                      return Card(
                        color: theme.colorScheme.onPrimary.withAlpha(85),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      getWeekday(dayIdx, true),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        translation(context: context, 'All'),
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                      ),
                                      Transform.scale(
                                        scale: 0.7,
                                        child: Switch.adaptive(
                                          padding: const EdgeInsets.all(0),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          value: uniformDays![dayIdx],
                                          onChanged: (val) async {
                                            setState(() {
                                              uniformDays![dayIdx] = val;
                                              if (val) {
                                                // unify users across meals for this day
                                                final all = <String>[];
                                                for (final mealUsers in localWeekPlan![dayIdx]) {
                                                  for (final u in mealUsers) {
                                                    if (!all.contains(u)) all.add(u);
                                                  }
                                                }
                                                for (int m = 0; m < widget.meals.length; m++) {
                                                  localWeekPlan![dayIdx][m] = List<String>.from(all);
                                                }
                                              }
                                            });
                                            final service = ref.read(cateringFirestoreServiceProvider);
                                            await service.setUniformDay(dayIdx, val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    padding: const EdgeInsets.all(0),
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final confirm = await showConfirmDialog(
                                        context: context,
                                        title: 'Delete Day',
                                        content: RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context).style,
                                            children: [
                                              const TextSpan(text: 'Are you sure you want to delete all entries for '),
                                              TextSpan(
                                                text: getWeekday(dayIdx, true),
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const TextSpan(text: '?'),
                                            ],
                                          ),
                                        ),
                                        confirmText: 'Delete',
                                      );
                                      if (confirm == true) {
                                        setState(() {
                                          localWeekPlan![dayIdx] = List.generate(widget.meals.length, (_) => []);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              // Drop zones: either single combined (uniform) or per-meal
                              if (uniformDays![dayIdx])
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: DragTarget<String>(
                                    builder: (context, candidateData, rejectedData) {
                                      final usersAll = localWeekPlan![dayIdx][0];
                                      return Container(
                                        constraints: const BoxConstraints(minHeight: 54),
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.background,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    translation(context: context, 'All meals'),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white70 : Colors.black87,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            usersAll.isNotEmpty
                                                ? Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: usersAll.map((user) => Container(
                                                      margin: const EdgeInsets.only(bottom: 2),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.08),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Row(
                                                        spacing: 4,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                for (int m = 0; m < widget.meals.length; m++) {
                                                                  localWeekPlan![dayIdx][m].remove(user);
                                                                }
                                                              });
                                                            },
                                                            child: Icon(Icons.remove_circle_outline, size: 18, color: isDark ? Colors.red[200] : Colors.red[700]),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              user,
                                                              style: TextStyle(color: isDark ? Colors.white : null),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )).toList(),
                                                  )
                                                : Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                    child: Center(
                                                      child: Text(
                                                        translation(context: context, 'Drag here for whole day'),
                                                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      );
                                    },
                                    onAccept: (user) {
                                      setState(() {
                                        for (int m = 0; m < widget.meals.length; m++) {
                                          final list = localWeekPlan![dayIdx][m];
                                          if (!list.contains(user)) list.add(user);
                                        }
                                      });
                                    },
                                  ),
                                )
                              else
                                Column(
                                  children: List.generate(widget.meals.length, (mealIdx) {
                                    final mealName = widget.mealsTranslated[mealIdx];
                                    final usersForMeal = localWeekPlan![dayIdx][mealIdx];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: DragTarget<String>(
                                        builder: (context, candidateData, rejectedData) {
                                          return Container(
                                            constraints: const BoxConstraints(minHeight: 54),
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.background,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: isDark ? Colors.white24 : Colors.grey),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.restaurant_menu, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        mealName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? Colors.white70 : Colors.black87,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                usersForMeal.isNotEmpty
                                                    ? Wrap(
                                                        spacing: 4,
                                                        runSpacing: 4,
                                                        children: usersForMeal.map((user) => Container(
                                                          margin: const EdgeInsets.only(bottom: 2),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.08),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            spacing: 4,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                      usersForMeal.remove(user);
                                                                  });
                                                                },
                                                                child: Icon(Icons.remove_circle_outline, size: 18, color: isDark ? Colors.red[200] : Colors.red[700]),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  user, 
                                                                  style: TextStyle(color: isDark ? Colors.white : null),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )).toList(),
                                                      )
                                                    : Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                        child: Center(
                                                          child: Text(
                                                            translation(context: context, 'Drag here for {mealName}').replaceFirst('{mealName}', mealName),
                                                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          );
                                        },
                                        onAccept: (user) {
                                          setState(() {
                                            if (!usersForMeal.contains(user)) {
                                              usersForMeal.add(user);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 160,
            color: isDark ? Colors.grey[900] : Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      // compute which users are already assigned somewhere in the localWeekPlan
                      final assignedUsers = <String>{};
                      for (final day in localWeekPlan!) {
                        for (final meal in day) {
                          for (final u in meal) {
                            assignedUsers.add(u);
                          }
                        }
                      }

                      return ListView(
                        children: users.map((user) {
                          final isAssigned = assignedUsers.contains(user);
                          final textColor = isAssigned
                              ? theme.colorScheme.onSurface.withOpacity(0.6)
                              : theme.colorScheme.primary;
                          final opacity = isAssigned ? 0.55 : 1.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: LongPressDraggable<String>(
                              data: user,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(user, style: TextStyle(color: textColor)),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(user, style: TextStyle(color: theme.colorScheme.primary)),
                                ),
                              ),
                              // LongPressDraggable starts the drag after a long press, which avoids accidental drags while scrolling on mobile
                              child: Opacity(
                                opacity: opacity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 17, // slightly larger
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAssigned)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6.0),
                                          child: Icon(Icons.check_circle_outline, size: 16, color: textColor),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving
            ? null
            : () async {
                setState(() => isSaving = true);
                final service = ref.read(cateringFirestoreServiceProvider);
                await service.setWeekPlan(localWeekPlan!);
                setState(() => isSaving = false);
                if (context.mounted) Navigator.pop(context, localWeekPlan);
              },
        tooltip: 'Save and go back',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: isSaving ? const CircularProgressIndicator() : const Icon(Icons.save),
      ),
    );
  }
}
