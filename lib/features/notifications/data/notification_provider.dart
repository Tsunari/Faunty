import 'package:faunty/features/notifications/data/app_notification.dart';

/// Interface for notification providers (OneSignal, FCM, etc.).
abstract class NotificationProvider {
  /// Initialize the provider.
  Future<void> init();

  /// Request permission from the user.
  Future<bool> requestPermission();

  /// Identify the user (login).
  Future<void> login(String externalId);

  /// Clear user identity (logout).
  Future<void> logout();

  /// Send a notification.
  Future<void> send(AppNotification notification, {List<String>? toUserIds});
}