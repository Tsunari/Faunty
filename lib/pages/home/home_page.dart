import 'package:faunty/components/role_gate.dart';
import 'package:faunty/helper/logging.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/models/user_entity.dart';
import 'package:faunty/pages/more/kantin_page.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:faunty/tools/update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/fcm/custom_tokens_dialog.dart';
import '../../notifications/one_signal/custom_tokens_dialog.dart';
import '../../notifications/one_signal/onesignal_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/custom_app_bar.dart';
import 'package:faunty/notifications/notification_manager.dart';
import 'package:faunty/state_management/user_provider.dart';
import '../../state_management/program_provider.dart';
import '../../state_management/catering_provider.dart';
import '../../state_management/cleaning_provider.dart';
import 'home_drawer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();
  late Timer _timer;
  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  static const List<String> weekDaysFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> weekDaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> mealNames = [
    'Breakfast', 'Lunch', 'Dinner'
  ];

  List<Map<String, String>> getNextAppointments(Map<String, List<Map<String, String>>>? weekProgram) {
    if (weekProgram == null) return [];
    final now = DateTime.now();
    final todayIdx = now.weekday - 1; // Monday=0
    final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    List<Map<String, String>> upcoming = [];
    for (int i = 0; i < 7; i++) {
      final dayIdx = (todayIdx + i) % 7;
      final dayFull = weekDaysFull[dayIdx];
      final dayShort = weekDaysShort[dayIdx];
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
          'from': event['from']! ,
          'to': event['to']! ,
          'event': event['event']! ,
        });
        if (upcoming.length >= 10) return upcoming;
      }
    }
    return upcoming;
  }

  @override
  void initState() {
    super.initState();
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

      // // Only check and request notification permission from Home.
      // // The full NotificationService.init() should run early (e.g., in main()).
      // if (!_notificationInitialized && user != null) {
      //   _notificationInitialized = true;
      //   try {
      //     await NotificationService.checkAndRequestPermission(requestIfNot: true);
      //   } catch (e) {
      //     if (mounted) {
      //       if (kDebugMode) print('Notification permission check/request error: $e');
      //     }
      //   }
      // }
    });
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

        final weekProgramAsync = ref.watch(weekProgramProvider);
        final cateringAsync = ref.watch(cateringWeekPlanProvider);
        final cleaningAsync = ref.watch(cleaningDataProvider);
        final width = MediaQuery.of(context).size.width;
        return Scaffold(
          drawer: const HomeDrawer(),
          appBar: CustomAppBar(
            title: translation(context: context, 'Home'),
            actions: [
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
          ),
          body: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  SizedBox(
                    width: width,
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation(context: context, 'Program'),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            weekProgramAsync.when(
                              data: (data) {
                                final appointments = getNextAppointments(data);
                                if (appointments.isEmpty) {
                                  return Text(translation(context: context, 'No program entries found for this week.'));
                                }
                                final now = DateTime.now();
                                final todayIdx = now.weekday - 1;
                                final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
                                return Column(
                                  children: appointments.asMap().entries.map((entry) {
                                    final a = entry.value;
                                    bool isCurrent = false;
                                    final eventDayIdx = weekDaysShort.indexOf(a['day']!);
                                    if (eventDayIdx == todayIdx) {
                                      final fromParts = a['from']!.split(':');
                                      final from = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
                                      // Find next event for today
                                      TimeOfDay? nextFrom;
                                      if (entry.key < appointments.length - 1) {
                                        final next = appointments[entry.key + 1];
                                        final nextDayIdx = weekDaysShort.indexOf(next['day']!);
                                        if (nextDayIdx == todayIdx) {
                                          final nextFromParts = next['from']!.split(':');
                                          nextFrom = TimeOfDay(hour: int.parse(nextFromParts[0]), minute: int.parse(nextFromParts[1]));
                                        }
                                      }
                                      bool afterFrom = nowTime.hour > from.hour || (nowTime.hour == from.hour && nowTime.minute >= from.minute);
                                      bool beforeNext = nextFrom == null || (nowTime.hour < nextFrom.hour || (nowTime.hour == nextFrom.hour && nowTime.minute < nextFrom.minute));
                                      isCurrent = afterFrom && beforeNext;
                                    }
                                    bool isNewDay = false;
                                    if (entry.key == 0) {
                                      isNewDay = true;
                                    } else {
                                      final prev = appointments[entry.key - 1];
                                      isNewDay = a['day'] != prev['day'];
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isNewDay && entry.key != 0) const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isCurrent ? Colors.red : Theme.of(context).colorScheme.primary.withAlpha(200),
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${a['day']} ',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text('${a['from']} - ${a['to']}: '),
                                                Expanded(child: Text(a['event']!)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.dining, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: cateringAsync.when(
                              data: (data) {
                                final now = DateTime.now();
                                final todayIdx = now.weekday - 1; // Monday=0
                                for (int offset = 0; offset < 7; offset++) {
                                  final dayIdx = (todayIdx + offset) % 7;
                                  final List<int> assignedMeals = [];
                                  final fullName = "${user.firstName} ${user.lastName}";
                                  for (int meal = 0; meal < data[dayIdx].length; meal++) {
                                    final names = data[dayIdx][meal];
                                    if (names.contains(fullName)) {
                                      assignedMeals.add(meal);
                                    }
                                  }
                                  if (assignedMeals.isNotEmpty) {
                                    final isToday = offset == 0;
                                    final weekday = isToday ? translation(context: context, 'Today') : weekDaysFull[dayIdx];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          translation(context: context, 'Your next catering assignment:'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              weekday,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const Text(': '),
                                            ...assignedMeals.asMap().entries.map((entry) => Row(
                                              children: [
                                                Text(
                                                  mealNames[entry.value],
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary),
                                                ),
                                                if (entry.key != assignedMeals.length - 1)
                                                  const Text(', '),
                                              ],
                                            )),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                }
                                return Text(translation(context: context, 'No upcoming catering assignment found.'));
                              },
                              loading: () => Text(translation(context: context, 'Catering wird geladen...')),
                              error: (e, s) => Text(translation(context: context, 'Error loading Catering.')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: cleaningAsync.when(
                              data: (data) {
                                final places = data as Map<String, dynamic>? ?? {};
                                if (places.isEmpty) {
                                  return Text(translation(context: context, 'No cleaning assignments found.'));
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
                                  return Text(translation(context: context, 'You have no cleaning assignment'));
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      translation(context: context, 'Your cleaning assignment:'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...userPlaces.map((place) => Text(
                                          place,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        )),
                                  ],
                                );
                              },
                              loading: () => Text(translation(context: context, 'Cleaning assignments are loading...')),
                              error: (e, s) => Text(translation(context: context, 'Error loading Cleaning data.')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: CantineWidget(placeId: user.placeId, userUid: user.uid, userRole: user.role))
                ],
              ),
            ),
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
  } // Ende build
} // Ende HomePage
