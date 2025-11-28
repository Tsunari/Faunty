import 'dart:convert';
import 'package:faunty/helper/logging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../notification_provider.dart';
import 'onesignal_bridge.dart';
import '../app_notification.dart';

class OneSignalNotificationProvider implements NotificationProvider {
  static const String _oneSignalAppId = 'f2a525de-b733-4e92-9494-dff5eae29756';

  // WARNING: Even with dotenv, this key is exposed in the client-side code.
  // Anyone who decompiles your app can find this key and send notifications.
  // The only secure way is to use a backend (Cloud Functions, Vercel, etc.).
  String get _oneSignalRestApiKey => dotenv.env['ONESIGNAL_REST_API_KEY'] ?? '';

  @override
  Future<void> init() async {
    // OneSignal web init is handled in index.html usually,
    // but we can do extra setup here if needed.
    if (kIsWeb) {
      // Already initialized in index.html
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      OneSignalHelper.requestPermission();
      return true; // Can't easily get result from void method yet
    }
    return false;
  }

  @override
  Future<void> login(String externalId) async {
    if (kIsWeb) {
      OneSignalHelper.login(externalId);
    }
  }

  @override
  Future<void> logout() async {
    if (kIsWeb) {
      OneSignalHelper.logout();
    }
  }

  @override
  Future<void> send(AppNotification notification, {List<String>? toUserIds}) async {
    if (_oneSignalRestApiKey.isEmpty || _oneSignalRestApiKey == 'YOUR_REST_API_KEY_HERE') {
      printError('Error: OneSignal REST API Key not set in .env file.');
      return;
    }

    try {
      final body = {
        'app_id': _oneSignalAppId,
        'headings': {'en': notification.title},
        'contents': {'en': notification.body},
        if (notification.payload != null) 'data': notification.payload,
        if (notification.imageUrl != null) ...{
          'chrome_web_image': notification.imageUrl,
          'big_picture': notification.imageUrl, // Android
          'ios_attachments': {'id1': notification.imageUrl}, // iOS
        },
        if (notification.launchUrl != null) 'url': notification.launchUrl,
        if (notification.deliveryTime != null) ...{
          'send_after': notification.deliveryTime!.toUtc().toIso8601String(),
          // Use a collapse_id based on the notification type + user/target to prevent duplicates
          // For now, we use the title as a simple collapse key or we could add a collapseKey to AppNotification
          'collapse_id': notification.title,
        },
        if (toUserIds != null && toUserIds.isNotEmpty)
          'include_external_user_ids': toUserIds
        else
          'included_segments': ['All'], // Send to everyone if no users specified
      };

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Basic $_oneSignalRestApiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        printInfo('Notification sent successfully: ${response.body}');
      } else {
        printError('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      printError('Error sending notification: $e');
    }
  }
}
