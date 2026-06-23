# Notification API

This directory contains the new notification API for Faunty. It is designed to be provider-agnostic, meaning you can switch between OneSignal, FCM, or any other provider without changing the application logic.

## Structure

- **`notification_manager.dart`**: The singleton class that manages notifications. Use `NotificationManager()` to access it.
- **`notification_provider.dart`**: The abstract interface that any notification provider must implement.
- **`app_notification.dart`**: The abstract base class for all notification types.
- **`types/`**: Directory where you define your specific notification types (e.g., `CateringTurnNotification`).
- **`one_signal/`**: Contains the OneSignal implementation of the `NotificationProvider`.
- **`fcm/`**: Contains the legacy FCM implementation.

## Usage

### 1. Define a Notification Type

Create a new class in `lib/notifications/types/` that extends `AppNotification`.

```dart
import '../app_notification.dart';

class MyCustomNotification extends AppNotification {
  final String userName;

  MyCustomNotification({required this.userName});

  @override
  String get title => 'Hello!';

  @override
  String get body => 'Welcome back, $userName.';

  @override
  Map<String, dynamic>? get payload => {
    'type': 'welcome',
    'user': userName,
  };
}
```

### 2. Send a Notification

Use the `NotificationManager` to send the notification.

```dart
import 'package:faunty/notifications/notification_manager.dart';
import 'package:faunty/notifications/types/my_custom_notification.dart';

void sendWelcome(String userId, String name) {
  final notification = MyCustomNotification(userName: name);
  // Send to a specific user
  NotificationManager().send(notification, toUserId: userId);
  
  // Or send to all users
  // NotificationManager().send(notification);
}
```

### 3. Initialization

The `NotificationManager` is initialized in `main.dart`.

```dart
NotificationManager().setProvider(OneSignalNotificationProvider());
NotificationManager().init();
```

### 4. Handling Permissions and Login

```dart
// Request permission
await NotificationManager().requestPermission();

// Login (associate device with user ID)
await NotificationManager().login(userId);

// Logout
await NotificationManager().logout();
```

## Switching Providers

To switch to a different provider (e.g., back to FCM), implement `NotificationProvider` for that service and update the initialization in `main.dart`.

```dart
// NotificationManager().setProvider(OneSignalNotificationProvider());
NotificationManager().setProvider(MyNewProvider());
```
