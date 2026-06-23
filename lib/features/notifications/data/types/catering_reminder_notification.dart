import 'package:faunty/features/notifications/data/app_notification.dart';

class CateringReminderNotification extends AppNotification {
  final String assigneeNames;
  final DateTime date;
  @override
  final DateTime? deliveryTime;

  CateringReminderNotification({
    required this.assigneeNames,
    required this.date,
    required this.deliveryTime,
  });

  @override
  String get title => 'Catering Reminder';

  @override
  String get body => 'Catering tomorrow: $assigneeNames';

  @override
  Map<String, dynamic>? get payload => {
    'type': 'catering_reminder',
    'date': date.toIso8601String(),
  };
}