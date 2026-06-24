import 'package:faunty/features/notifications/data/notification_provider.dart';
import 'package:faunty/features/notifications/data/app_notification.dart';

/// Singleton class that manages notifications for the application.
///
/// It delegates the actual notification handling to a [NotificationProvider]
/// (e.g., OneSignal, FCM), allowing for easy switching between providers.
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  
  /// Returns the singleton instance of [NotificationManager].
  factory NotificationManager() => _instance;
  
  NotificationManager._internal();

  late NotificationProvider _provider;

  /// Returns the currently active [NotificationProvider].
  NotificationProvider get provider => _provider;

  /// Sets the [NotificationProvider] to be used.
  ///
  /// This should be called early in the app initialization (e.g., in main.dart).
  void setProvider(NotificationProvider provider) {
    _provider = provider;
  }

  /// Initializes the configured provider.
  Future<void> init() async {
    await _provider.init();
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermission() async {
    return await _provider.requestPermission();
  }

  /// Associates the current device with a specific user ID.
  ///
  /// [externalId] is typically the user's UID from the authentication service.
  Future<void> login(String externalId) async {
    await _provider.login(externalId);
  }

  /// Dissociates the device from the current user.
  ///
  /// Should be called when the user logs out.
  Future<void> logout() async {
    await _provider.logout();
  }

  /// Sends a notification using the configured provider.
  ///
  /// [notification] is the notification object containing title, body, and payload.
  /// [toUserIds] is an optional list of user IDs to send the notification to.
  /// If [toUserIds] is null or empty, the behavior depends on the provider (e.g., send to all).
  Future<void> send(AppNotification notification, {List<String>? toUserIds}) async {
    await _provider.send(notification, toUserIds: toUserIds);
  }
}