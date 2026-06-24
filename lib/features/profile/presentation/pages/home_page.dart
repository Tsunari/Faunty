import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/core/utils/logging.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/profile/presentation/pages/kantin_page.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/utils/update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/notifications/data/fcm/custom_tokens_dialog.dart';
import 'package:faunty/features/notifications/data/one_signal/custom_tokens_dialog.dart';
import 'package:faunty/features/notifications/data/one_signal/onesignal_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/features/notifications/data/notification_manager.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/lists/presentation/controllers/program_provider.dart';
import 'package:faunty/features/lists/presentation/controllers/catering_provider.dart';
import 'package:faunty/features/lists/presentation/controllers/cleaning_provider.dart';
import 'package:faunty/features/profile/presentation/pages/home_drawer.dart';
import 'package:faunty/core/widgets/glass_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> _weekDaysFull = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const List<String> _weekDaysShort = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
];
const List<String> _mealNames = [
  'Breakfast', 'Lunch', 'Dinner'
];

List<Map<String, String>> _getNextAppointments(Map<String, List<Map<String, String>>>? weekProgram) {
  if (weekProgram == null) return [];
  final now = DateTime.now();
  final todayIdx = now.weekday - 1; // Monday=0
  final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
  List<Map<String, String>> upcoming = [];
  for (int i = 0; i < 7; i++) {
    final dayIdx = (todayIdx + i) % 7;
    final dayFull = _weekDaysFull[dayIdx];
    final dayShort = _weekDaysShort[dayIdx];
    final events = weekProgram[dayFull] ?? [];
    for (final event in events) {
      if (i == 0) {
        final fromParts = event['from']!.split(':');
        final toParts = event['to']!.split(':');
        final from = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
        final to = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
        // Only show if event is current or in the future
        bool afterFrom = nowTime.hour > from.hour || (nowTime.hour == from.hour && nowTime.minute >= from.minute);
        bool beforeTo = nowTime.hour < to.hour || (nowTime.hour == to.hour && nowTime.minute <= to.minute);
        if (!(afterFrom && beforeTo) && (from.hour < nowTime.hour || (from.hour == nowTime.hour && from.minute <= nowTime.minute))) {
          continue;
        }
      }
      upcoming.add({
        'day': dayShort,
        'from': event['from']!,
        'to': event['to']!,
        'event': event['event']!,
      });
      if (upcoming.length >= 10) return upcoming;
    }
  }
  return upcoming;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();
  late Timer _timer;
  bool _isEditMode = false;
  List<String> _currentOrder = ['program', 'catering', 'cleaning', 'cantine'];

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadWidgetOrder();
    // Sync timer to next full minute
    final now = DateTime.now();
    final secondsToNextMinute = 60 - now.second;
    _timer = Timer(Duration(seconds: secondsToNextMinute), () {
      if (mounted) setState(() {});
      // After first tick, switch to periodic 1-minute timer
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kIsWeb) {
        NotificationManager().requestPermission();
        UpdateService.manualCheck();
      }
    });
  }

  Future<void> _loadWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('home_card_order');
    if (saved != null && saved.isNotEmpty) {
      final valid = saved.where((id) => _widgetBuilders.containsKey(id)).toList();
      for (final id in ['program', 'catering', 'cleaning', 'cantine']) {
        if (!valid.contains(id)) {
          valid.add(id);
        }
      }
      if (mounted) {
        setState(() {
          _currentOrder = valid;
        });
      }
    }
  }

  Future<void> _saveWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('home_card_order', _currentOrder);
  }

  void _restoreDefaultOrder() {
    setState(() {
      _currentOrder = ['program', 'catering', 'cleaning', 'cantine'];
    });
    _saveWidgetOrder();
  }

  Map<String, Widget Function(UserEntity, bool)> get _widgetBuilders => {
    'program': (user, isDark) => _ProgramCard(user: user, isDark: isDark),
    'catering': (user, isDark) => _CateringCard(user: user, isDark: isDark),
    'cleaning': (user, isDark) => _CleaningCard(user: user, isDark: isDark),
    'cantine': (user, isDark) => _CantineCard(user: user, isDark: isDark),
  };

  Map<String, Map<String, dynamic>> get _widgetMeta => {
    'program': {
      'title': translation(context: context, 'Program'),
      'icon': Icons.calendar_today_rounded,
    },
    'catering': {
      'title': translation(context: context, 'Catering Assignment'),
      'icon': Icons.restaurant_rounded,
    },
    'cleaning': {
      'title': translation(context: context, 'Cleaning Assignment'),
      'icon': Icons.cleaning_services_rounded,
    },
    'cantine': {
      'title': translation(context: context, 'Cantine'),
      'icon': Icons.storefront_rounded,
    },
  };

  Widget _buildReorderableItem(String widgetId, int index, bool isDark) {
    final meta = _widgetMeta[widgetId];
    if (meta == null) return SizedBox(key: ValueKey(widgetId));
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      key: ValueKey(widgetId),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                meta['icon'] as IconData,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                meta['title'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = 1.0 + (0.02 * animValue);
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12 * animValue),
                  blurRadius: 12 * animValue,
                  offset: Offset(0, 6 * animValue),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user changes to ensure OneSignal login is called on auto-login
    ref.listen<AsyncValue<UserEntity?>>(userProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null && (previous?.asData?.value?.uid != user.uid)) {
        if (kIsWeb) {
          printInfo('User loaded/changed: ${user.uid}. Ensuring OneSignal login.');
          NotificationManager().login(user.uid);
        }
      }
    });

    final userAsync = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return userAsync.when(
      data: (user) {
        printInfo(user != null ? 'UserEntity: uid=${user.uid}, email=${user.email}, role=${user.role}, place=${user.placeId}' : 'UserEntity NOT LOADED');
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(translation(context: context, 'Waiting for UserEntity... (HomePage was built without a loaded user)'))
                ],
              ),
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          drawer: const HomeDrawer(),
          appBar: CustomAppBar(
            title: translation(context: context, 'Home'),
            actions: [
              if (_isEditMode) ...[
                IconButton(
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  tooltip: translation(context: context, 'Restore Defaults'),
                  onPressed: _restoreDefaultOrder,
                ),
                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  tooltip: translation(context: context, 'Done'),
                  onPressed: () {
                    setState(() => _isEditMode = false);
                    _saveWidgetOrder();
                  },
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  tooltip: translation(context: context, 'Customize Layout'),
                  onPressed: () => setState(() => _isEditMode = true),
                ),
                kDebugMode
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () async {
                            if (NotificationManager().provider is OneSignalNotificationProvider) {
                              await showOneSignalDialog(context, ref);
                            } else {
                              await showTokensDialog(context, ref);
                            }
                          },
                        ),
                      )
                    : RoleGate(
                        minRole: UserRole.superuser,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.notifications),
                            onPressed: () async {
                              if (NotificationManager().provider is OneSignalNotificationProvider) {
                                await showOneSignalDialog(context, ref);
                              } else {
                                await showTokensDialog(context, ref);
                              }
                            },
                          ),
                        ),
                      ),
              ],
            ],
          ),
          body: Stack(
            children: [
              // Background decorative blobs for visual depth and premium glassmorphic feel
              Positioned(
                top: 40,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.015),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: -60,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.01),
                  ),
                ),
              ),
              Positioned.fill(
                child: Scrollbar(
                  controller: _scrollController,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _isEditMode
                          ? ReorderableListView(
                              buildDefaultDragHandles: false,
                              proxyDecorator: _proxyDecorator,
                              scrollController: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = _currentOrder.removeAt(oldIndex);
                                  _currentOrder.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (int i = 0; i < _currentOrder.length; i++)
                                  _buildReorderableItem(_currentOrder[i], i, isDark),
                              ],
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 80),
                                  for (final widgetId in _currentOrder) ...[
                                    _widgetBuilders[widgetId]!(user, isDark),
                                    const SizedBox(height: 12),
                                  ],
                                  const SizedBox(height: 78),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error loading user: $e')),
      ),
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  final UserEntity user;
  final bool isDark;
  const _ProgramCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekProgramAsync = ref.watch(weekProgramProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final lineColor = onSurfaceColor.withOpacity(0.15);

    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  translation(context: context, 'Program'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            weekProgramAsync.when(
              data: (data) {
                final appointments = _getNextAppointments(data);
                if (appointments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      translation(context: context, 'No program entries found for this week.'),
                      style: TextStyle(
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                final now = DateTime.now();
                final todayIdx = now.weekday - 1;
                final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

                return Column(
                  children: appointments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    bool isCurrent = false;
                    final eventDayIdx = _weekDaysShort.indexOf(a['day']!);
                    if (eventDayIdx == todayIdx) {
                      final fromParts = a['from']!.split(':');
                      final from = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
                      // Find next event for today
                      TimeOfDay? nextFrom;
                      if (index < appointments.length - 1) {
                        final next = appointments[index + 1];
                        final nextDayIdx = _weekDaysShort.indexOf(next['day']!);
                        if (nextDayIdx == todayIdx) {
                          final nextFromParts = next['from']!.split(':');
                          nextFrom = TimeOfDay(hour: int.parse(nextFromParts[0]), minute: int.parse(nextFromParts[1]));
                        }
                      }
                      bool afterFrom = nowTime.hour > from.hour || (nowTime.hour == from.hour && nowTime.minute >= from.minute);
                      bool beforeNext = nextFrom == null || (nowTime.hour < nextFrom.hour || (nowTime.hour == nextFrom.hour && nowTime.minute < nextFrom.minute));
                      isCurrent = afterFrom && beforeNext;
                    }

                    final isFirst = index == 0;
                    final isLast = index == appointments.length - 1;
                    final cardBgColor = isCurrent
                        ? primaryColor.withOpacity(isDark ? 0.12 : 0.08)
                        : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.015));

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left vertical timeline indicator
                          SizedBox(
                            width: 24,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    width: 2,
                                    color: isFirst ? Colors.transparent : lineColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: isCurrent ? 14 : 10,
                                  height: isCurrent ? 14 : 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent ? primaryColor : onSurfaceColor.withOpacity(0.3),
                                    boxShadow: isCurrent ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: 2,
                                    color: isLast ? Colors.transparent : lineColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right side: The event Card block
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrent 
                                        ? primaryColor.withOpacity(0.4)
                                        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                    width: 1,
                                  ),
                                  boxShadow: isCurrent ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: isCurrent ? primaryColor : Colors.transparent,
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${a['day']} • ${a['from']} - ${a['to']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent ? primaryColor : onSurfaceColor.withOpacity(0.6),
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  translation(context: context, 'NOW'),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          a['event']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            color: onSurfaceColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text(translation(context: context, 'Error loading Program: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CateringCard extends ConsumerWidget {
  final UserEntity user;
  final bool isDark;
  const _CateringCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cateringAsync = ref.watch(cateringWeekPlanProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                translation(context: context, 'Catering Assignment'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          cateringAsync.when(
            data: (data) {
              final now = DateTime.now();
              final todayIdx = now.weekday - 1; // Monday=0
              String? assignedWeekday;
              List<int> assignedMeals = [];
              
              for (int offset = 0; offset < 7; offset++) {
                final dayIdx = (todayIdx + offset) % 7;
                final List<int> meals = [];
                final fullName = "${user.firstName} ${user.lastName}";
                for (int meal = 0; meal < data[dayIdx].length; meal++) {
                  final names = data[dayIdx][meal];
                  if (names.contains(fullName)) {
                    meals.add(meal);
                  }
                }
                if (meals.isNotEmpty) {
                  final isToday = offset == 0;
                  assignedWeekday = isToday ? translation(context: context, 'Today') : _weekDaysFull[dayIdx];
                  assignedMeals = meals;
                  break;
                }
              }
              
              if (assignedWeekday != null && assignedMeals.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(isDark ? 0.08 : 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignedWeekday,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        translation(context: context, 'You are assigned to prepare:'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: assignedMeals.map((mealIdx) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mealIdx == 0 
                                      ? Icons.wb_sunny_rounded
                                      : mealIdx == 1
                                          ? Icons.lunch_dining_rounded
                                          : Icons.dinner_dining_rounded,
                                  size: 14,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  translation(context: context, _mealNames[mealIdx]),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        translation(context: context, 'No upcoming catering assignment found.'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translation(context: context, 'Catering wird geladen...')),
              ),
            ),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translation(context: context, 'Error loading Catering.')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleaningCard extends ConsumerWidget {
  final UserEntity user;
  final bool isDark;
  const _CleaningCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleaningAsync = ref.watch(cleaningDataProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cleaning_services_rounded,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                translation(context: context, 'Cleaning Assignment'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          cleaningAsync.when(
            data: (data) {
              final places = data as Map<String, dynamic>? ?? {};
              if (places.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    translation(context: context, 'No cleaning assignments found.'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }
              final userPlaces = <String>[];
              places.forEach((placeId, placeData) {
                if (placeData is Map) {
                  final assignees = placeData['assignees'];
                  if (assignees is List && assignees.any((a) {
                    if (a is String) {
                      final assigneeUid = a.split('_').first;
                      return assigneeUid == user.uid;
                    }
                    return false;
                  })) {
                    userPlaces.add(placeData['name'] as String? ?? placeId);
                  }
                }
              });
              if (userPlaces.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          translation(context: context, 'You have no cleaning assignment'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation(context: context, 'Your cleaning assignment:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...userPlaces.map((place) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              place,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              translation(context: context, 'Pending'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translation(context: context, 'Cleaning assignments are loading...')),
              ),
            ),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translation(context: context, 'Error loading Cleaning data.')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CantineCard extends ConsumerWidget {
  final UserEntity user;
  final bool isDark;
  const _CantineCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CantineWidget(
        placeId: user.placeId,
        userUid: user.uid,
        userRole: user.role,
      ),
    );
  }
}