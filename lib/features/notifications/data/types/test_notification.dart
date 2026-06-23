import 'package:faunty/features/notifications/data/app_notification.dart';

class TestNotification extends AppNotification {
  @override
  String get title => 'Test Notification';

  @override
  String get body => 'This is a test notification from the new API!';

  @override
  Map<String, dynamic>? get payload => {
    'type': 'test',
    'timestamp': DateTime.now().toIso8601String(),
  };
}