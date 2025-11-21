import '../app_notification.dart';

class CateringTurnNotification extends AppNotification {
  final String userName;
  final DateTime date;

  CateringTurnNotification({required this.userName, required this.date});

  @override
  String get title => 'Catering Duty';

  @override
  String get body => 'Hello $userName, it is your turn for catering on ${date.day}/${date.month}.';

  @override
  Map<String, dynamic>? get payload => {
    'type': 'catering_turn',
    'date': date.toIso8601String(),
  };
}
