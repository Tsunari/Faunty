import 'package:faunty/models/feedback_report.dart';
import '../app_notification.dart';

class FeedbackStatusNotification extends AppNotification {
  final String reportTitle;
  final FeedbackStatus newStatus;
  final String reportId;

  FeedbackStatusNotification({
    required this.reportTitle,
    required this.newStatus,
    required this.reportId,
  });

  @override
  String get title => 'Feedback Update';

  @override
  String get body => 'Your feedback "$reportTitle" is now ${newStatus.label}.';

  @override
  Map<String, dynamic> get payload => {
        'type': 'feedback_status_update',
        'reportId': reportId,
      };
}

class FeedbackCommentNotification extends AppNotification {
  final String reportTitle;
  final String commenterName;
  final String commentText;
  final String reportId;

  FeedbackCommentNotification({
    required this.reportTitle,
    required this.commenterName,
    required this.commentText,
    required this.reportId,
  });

  @override
  String get title => 'New Comment on Feedback';

  @override
  String get body => '$commenterName commented on "$reportTitle": $commentText';

  @override
  Map<String, dynamic> get payload => {
        'type': 'feedback_new_comment',
        'reportId': reportId,
      };
}
