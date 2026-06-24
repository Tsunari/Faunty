import 'package:faunty/features/lists/data/repositories/catering_firestore_service.dart';
import 'package:faunty/features/profile/data/repositories/globals_firestore_service.dart';
import 'package:faunty/core/utils/logging.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/notifications/data/notification_manager.dart';
import 'package:faunty/features/notifications/data/types/catering_reminder_notification.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central manager for all scheduled/recurring reminders.
class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();
  factory ReminderManager() => _instance;
  ReminderManager._internal();

  /// Monitor user changes to schedule reminders.
  /// Call this inside the `build` method of a ConsumerWidget.
  void monitor(WidgetRef ref) {
    _initCateringReminders(ref);
    // Future: _initProgramReminders(ref);
  }

  void _initCateringReminders(WidgetRef ref) {
    // We listen to the user provider to get the current user
    // And then we listen to the catering service for that user's place

    ref.listen<AsyncValue<UserEntity?>>(userProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          _checkAndScheduleCatering(user);
        }
      });
    });
  }

  Future<void> _checkAndScheduleCatering(UserEntity user) async {
    // 0. Check if feature is enabled for this place
    final globalsService = GlobalsFirestoreService(user.placeId);
    try {
      final globalsStream = globalsService.globalsStream();
      final globals = await globalsStream.first;
      final isEnabled =
          globals['cateringReminderEnabled'] as bool? ??
          true; // Default to true

      if (!isEnabled) {
        // Feature disabled by admin, do not schedule.
        return;
      }
    } catch (e) {
      printError('Error fetching globals for catering reminder: $e');
      // Continue with default true if error? Or fail safe?
      // Let's continue assuming enabled if we can't fetch, or return.
      // Better to fail safe and not spam if unsure, but usually default true is better UX.
    }

    final service = CateringFirestoreService(user);

    try {
      // 1. Calculate "Tomorrow"
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // 0 = Monday, 6 = Sunday in our app logic usually?
      // DateTime.weekday: 1 = Monday, 7 = Sunday.
      // Our Firestore keys are 0-based (0=Monday).
      final tomorrowIndex = tomorrow.weekday - 1;

      // 2. Fetch Week Plan
      final weekPlanStream = service.watchWeekPlan();
      final weekPlan = await weekPlanStream.first;

      // 3. Check assignments for tomorrow (all meals)
      final List<String> myAssignments = [];
      final List<String> allAssignees = [];

      if (tomorrowIndex >= 0 && tomorrowIndex < 7) {
        final dayPlan = weekPlan[tomorrowIndex];
        for (final mealUsers in dayPlan) {
          if (mealUsers.contains(user.uid)) {
            myAssignments.add(user.uid);
          }
          allAssignees.addAll(mealUsers);
        }
      }

      if (myAssignments.isNotEmpty) {
        // 4. Schedule Notification
        // Schedule for 10:00 AM tomorrow
        final scheduledTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          22, // 10:00 PM
          0,
        );

        // Check if we already scheduled for this date to avoid spamming API
        final prefs = await SharedPreferences.getInstance();
        final lastScheduledKey = 'catering_reminder_last_scheduled_${user.uid}';
        final lastScheduledIso = prefs.getString(lastScheduledKey);

        final dateKey = "${tomorrow.year}-${tomorrow.month}-${tomorrow.day}";

        if (lastScheduledIso != dateKey) {
          final notification = CateringReminderNotification(
            assigneeNames: "Check app for details",
            date: tomorrow,
            deliveryTime: scheduledTime,
          );

          await NotificationManager().send(notification, toUserIds: [user.uid]);

          // Save state
          await prefs.setString(lastScheduledKey, dateKey);
        }
      }
    } catch (e) {
      // Log error but don't crash
      printError('Error scheduling catering reminder: $e');
    }
  }

  /// Manually schedule a test notification.
  Future<void> scheduleCateringTest(UserEntity user, Duration delay) async {
    try {
      final scheduledTime = DateTime.now().add(delay);
      final notification = CateringReminderNotification(
        assigneeNames: "TEST: You, Test User",
        date: DateTime.now().add(const Duration(days: 1)),
        deliveryTime: scheduledTime,
      );

      await NotificationManager().send(notification, toUserIds: [user.uid]);
      printInfo('Test notification scheduled for $scheduledTime');
    } catch (e) {
      printError('Error scheduling test notification: $e');
      rethrow;
    }
  }
}