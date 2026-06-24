import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/presentation/controllers/catering_provider.dart';
import 'package:faunty/core/widgets/custom_confirm_dialog.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class CateringOrganisationPage extends ConsumerStatefulWidget {
  final List<List<List<String>>> weekPlan;
  final List<String> users;
  final List<String> meals;
  final List<String> mealsTranslated;

  const CateringOrganisationPage({
    super.key,
    required this.weekPlan,
    required this.users,
    required this.meals,
    required this.mealsTranslated,
  });

  @override
  ConsumerState<CateringOrganisationPage> createState() => _CateringOrganisationPageState();
}

class _CateringOrganisationPageState extends ConsumerState<CateringOrganisationPage> {
  List<List<List<String>>>? localWeekPlan;
  bool isSaving = false;
  List<bool>? uniformDays;
  Map<String, String>? slotNames; // keys like '0_3' -> 'Cleaning'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final weekPlanAsync = ref.watch(cateringWeekPlanProvider);
    if (weekPlanAsync is AsyncData<List<List<List<String>>>>) {
      final firestorePlan = weekPlanAsync.value;
      if (localWeekPlan == null || !_deepEquals(localWeekPlan!, firestorePlan)) {
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
    final slotNamesAsync = ref.watch(cateringSlotNamesProvider);
    if (slotNamesAsync is AsyncData<Map<String, String>>) {
      final firestoreNames = slotNamesAsync.value;
      if (slotNames == null || slotNames!.toString() != firestoreNames.toString()) {
        slotNames = Map<String, String>.from(firestoreNames);
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
      translation(context: context, 'Monday'),
      translation(context: context, 'Tuesday'),
      translation(context: context, 'Wednesday'),
      translation(context: context, 'Thursday'),
      translation(context: context, 'Friday'),
      translation(context: context, 'Saturday'),
      translation(context: context, 'Sunday')
    ];
    return translated ? daysTranslated[weekday % 7] : days[weekday % 7];
  }

  Future<void> _renameOrDeleteCustomSlot(int dayIdx, int mealIdx) async {
    final mealKey = '${dayIdx}_$mealIdx';
    final controller = TextEditingController(text: slotNames![mealKey] ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            translation(context: ctx, 'Rename assignment'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: translation(context: ctx, 'Name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(translation(context: ctx, 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(translation(context: ctx, 'Save')),
          ),
          TextButton(
            onPressed: () async {
              final confirmDel = await showConfirmDialog(
                context: ctx,
                title: translation(context: context, 'Delete assignment'),
                content: Text(translation(context: context, 'Are you sure you want to delete this assignment slot?')),
                confirmText: translation(context: context, 'Delete'),
              );
              if (confirmDel == true) Navigator.pop(ctx, '__DELETE__');
            },
            child: Text(
              translation(context: context, 'Delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (res != null) {
      if (res == '__DELETE__') {
        setState(() {
          localWeekPlan![dayIdx].removeAt(mealIdx);
          final newSlotNames = Map<String, String>.from(slotNames!);
          newSlotNames.remove('${dayIdx}_$mealIdx');
          int i = mealIdx + 1;
          while (true) {
            final oldKey = '${dayIdx}_$i';
            if (!newSlotNames.containsKey(oldKey)) break;
            final val = newSlotNames.remove(oldKey)!;
            newSlotNames['${dayIdx}_${i - 1}'] = val;
            i++;
          }
          slotNames = newSlotNames;
        });
      } else {
        setState(() {
          if (res.isEmpty) {
            slotNames!.remove('${dayIdx}_$mealIdx');
          } else {
            slotNames!['${dayIdx}_$mealIdx'] = res;
          }
        });
      }
      try {
        final service = ref.read(cateringFirestoreServiceProvider);
        await service.setSlotNames(Map<String, String>.from(slotNames ?? {}));
      } catch (_) {}
    }
  }

  Future<void> _showQuickAssignDialog(int dayIdx, int mealIdx) async {
    final defaultMeal = mealIdx < widget.mealsTranslated.length ? widget.mealsTranslated[mealIdx] : null;
    final mealName = slotNames!['${dayIdx}_$mealIdx'] ?? defaultMeal ?? '${translation(context: context, 'Assignment')} ${mealIdx + 1}';
    final assigned = localWeekPlan![dayIdx][mealIdx];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Center(
                child: Text(
                  '${translation(context: ctx, 'Assign to')} $mealName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView.builder(
                  itemCount: widget.users.length,
                  itemBuilder: (context, idx) {
                    final user = widget.users[idx];
                    final isSelected = assigned.contains(user);
                    return CheckboxListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(user),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          setState(() {
                            if (val == true) {
                              if (!assigned.contains(user)) assigned.add(user);
                            } else {
                              assigned.remove(user);
                            }
                          });
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(translation(context: context, 'Done')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showQuickAssignUniformDialog(int dayIdx) async {
    List<String> assigned = [];
    final defaultCount = widget.meals.length;
    if (defaultCount > 0) {
      Set<String> inter = localWeekPlan![dayIdx][0].toSet();
      for (int m = 1; m < defaultCount; m++) {
        inter = inter.intersection(localWeekPlan![dayIdx][m].toSet());
      }
      assigned = inter.toList();
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Center(
                child: Text(
                  translation(context: ctx, 'Assign to all meals'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView.builder(
                  itemCount: widget.users.length,
                  itemBuilder: (context, idx) {
                    final user = widget.users[idx];
                    final isSelected = assigned.contains(user);
                    return CheckboxListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(user),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          setState(() {
                            if (val == true) {
                              for (int m = 0; m < widget.meals.length; m++) {
                                final list = localWeekPlan![dayIdx][m];
                                if (!list.contains(user)) list.add(user);
                              }
                              assigned.add(user);
                            } else {
                              for (int m = 0; m < widget.meals.length; m++) {
                                localWeekPlan![dayIdx][m].remove(user);
                              }
                              assigned.remove(user);
                            }
                          });
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(translation(context: context, 'Done')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMealSlot(int dayIdx, int mealIdx) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultMeal = mealIdx < widget.mealsTranslated.length ? widget.mealsTranslated[mealIdx] : null;
    final mealKey = '${dayIdx}_$mealIdx';
    final mealName = slotNames![mealKey] ?? defaultMeal ?? '${translation(context: context, 'Assignment')} ${mealIdx + 1}';
    final usersForMeal = localWeekPlan![dayIdx][mealIdx];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 60),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isOver 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOver
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isOver ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      mealIdx == 0 
                          ? Icons.wb_sunny_rounded 
                          : (mealIdx == 1 ? Icons.lunch_dining_rounded : Icons.nights_stay_rounded),
                      size: 16, 
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mealName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.person_add_alt_1_rounded, size: 18, color: theme.colorScheme.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: translation(context: context, 'Assign users'),
                      onPressed: () => _showQuickAssignDialog(dayIdx, mealIdx),
                    ),
                    if (mealIdx >= widget.meals.length) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, size: 18, color: theme.colorScheme.secondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _renameOrDeleteCustomSlot(dayIdx, mealIdx),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                usersForMeal.isNotEmpty
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: usersForMeal.map((user) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user,
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      usersForMeal.remove(user);
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel_rounded,
                                    size: 16,
                                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          translation(context: context, 'No assignments (Drag here)'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (localWeekPlan == null || uniformDays == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    slotNames ??= {};
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Helper to calculate assigned users
    final assignedUsers = <String>{};
    for (final day in localWeekPlan!) {
      for (final meal in day) {
        for (final u in meal) {
          assignedUsers.add(u);
        }
      }
    }

    Widget buildUserChip(String user) {
      final isAssigned = assignedUsers.contains(user);
      final textColor = isAssigned
          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
          : theme.colorScheme.primary;
      final opacity = isAssigned ? 0.55 : 1.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        child: LongPressDraggable<String>(
          data: user,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Text(user, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(user, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
            ),
          ),
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAssigned 
                    ? theme.colorScheme.surfaceVariant.withValues(alpha: 0.3) 
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAssigned 
                      ? Colors.transparent 
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAssigned) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check_circle_rounded, size: 14, color: textColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final workspaceListView = ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: 7,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, dayIdx) {
        return Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      getWeekday(dayIdx, true),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          translation(context: context, 'All'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch.adaptive(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: uniformDays![dayIdx],
                            onChanged: (val) async {
                              setState(() {
                                uniformDays![dayIdx] = val;
                                if (val) {
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
                        Icons.delete_sweep_rounded,
                        color: theme.colorScheme.error.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      tooltip: translation(context: context, 'Clear Day'),
                      onPressed: () async {
                        final confirm = await showConfirmDialog(
                          context: context,
                          title: 'Clear Day',
                          content: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(text: 'Are you sure you want to delete all entries for '),
                                TextSpan(
                                  text: getWeekday(dayIdx, true),
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
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
                            final keysToRemove = slotNames!.keys.where((k) => k.startsWith('$dayIdx' + '_')).toList();
                            for (final k in keysToRemove) slotNames!.remove(k);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 16, thickness: 0.5),
                // Drop zones
                if (uniformDays![dayIdx])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DragTarget<String>(
                          builder: (context, candidateData, rejectedData) {
                            final isOver = candidateData.isNotEmpty;
                            List<String> usersAll = [];
                            final defaultCount = widget.meals.length;
                            if (defaultCount > 0) {
                              Set<String> inter = localWeekPlan![dayIdx][0].toSet();
                              for (int m = 1; m < defaultCount; m++) {
                                inter = inter.intersection(localWeekPlan![dayIdx][m].toSet());
                              }
                              usersAll = inter.toList();
                            }
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              constraints: const BoxConstraints(minHeight: 60),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isOver 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                    : theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isOver
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                  width: isOver ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded, size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          translation(context: context, 'All meals'),
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.person_add_alt_1_rounded, size: 18, color: theme.colorScheme.primary),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: translation(context: context, 'Assign users'),
                                        onPressed: () => _showQuickAssignUniformDialog(dayIdx),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  usersAll.isNotEmpty
                                      ? Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: usersAll.map((user) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    user,
                                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        for (int m = 0; m < widget.meals.length; m++) {
                                                          localWeekPlan![dayIdx][m].remove(user);
                                                        }
                                                      });
                                                    },
                                                    child: Icon(
                                                      Icons.cancel_rounded,
                                                      size: 16,
                                                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            translation(context: context, 'No assignments (Drag here)'),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                        if (localWeekPlan![dayIdx].length > widget.meals.length) ...[
                          const SizedBox(height: 8),
                          for (int mealIdx = widget.meals.length; mealIdx < localWeekPlan![dayIdx].length; mealIdx++)
                            _buildMealSlot(dayIdx, mealIdx),
                        ],
                      ],
                    ),
                  )
                else
                  Column(
                    children: List.generate(
                      localWeekPlan![dayIdx].length,
                      (mealIdx) => _buildMealSlot(dayIdx, mealIdx),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            final newIdx = localWeekPlan![dayIdx].length;
                            localWeekPlan![dayIdx].add(<String>[]);
                            slotNames!['${dayIdx}_$newIdx'] = translation(context: context, 'Custom');
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: Text(
                          translation(context: context, 'Add assignment'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Catering Organisation'),
        useModern: false,
      ),
      body: isMobile
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Text(
                          translation(context: context, 'Users') + ' (${translation(context: context, 'Drag or Tap on Slot')})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          itemCount: users.length,
                          itemBuilder: (context, uIdx) => buildUserChip(users[uIdx]),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: workspaceListView),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: workspaceListView,
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                Container(
                  width: 200,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        child: Text(
                          translation(context: context, 'Users'),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: users.length,
                          itemBuilder: (context, uIdx) => buildUserChip(users[uIdx]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving
            ? null
            : () async {
                setState(() => isSaving = true);
                final service = ref.read(cateringFirestoreServiceProvider);
                await service.setWeekPlan(localWeekPlan!);
                if (slotNames != null && slotNames!.isNotEmpty) {
                  await service.setSlotNames(slotNames!.map((k, v) => MapEntry(k, v)));
                }
                setState(() => isSaving = false);
                if (context.mounted) Navigator.pop(context, localWeekPlan);
              },
        label: Text(
          translation(context: context, 'Save'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}