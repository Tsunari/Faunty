/// Base class for all application notifications.
/// Extend this class to define specific notification types with their own logic.
abstract class AppNotification {
  /// The title of the notification.
  String get title;

  /// The body text of the notification.
  String get body;

  /// Optional payload data to send with the notification.
  Map<String, dynamic>? get payload => null;

  /// Optional schedule time. If null, send immediately.
  DateTime? get scheduleTime => null;

  /// Target user IDs (external IDs).
  List<String>? get targetUserIds => null;

  /// Target segments (e.g. "Active Users").
  List<String>? get targetSegments => null;
}
