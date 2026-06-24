import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:faunty/features/notifications/data/notification_provider.dart';
import 'package:faunty/features/notifications/data/one_signal/onesignal_bridge.dart';
import 'package:faunty/features/notifications/data/app_notification.dart';
import 'package:faunty/core/constants/firestore_paths.dart';

class OneSignalNotificationProvider implements NotificationProvider {
  static const String _oneSignalAppId = 'f2a525de-b733-4e92-9494-dff5eae29756';

  @override
  Future<void> init() async {
    if (!kIsWeb) {
      OneSignalHelper.initialize();
    }
  }

  @override
  Future<bool> requestPermission() async {
    OneSignalHelper.requestPermission();
    return true;
  }

  @override
  Future<void> login(String externalId) async {
    OneSignalHelper.login(externalId);
  }

  @override
  Future<void> logout() async {
    OneSignalHelper.logout();
  }

  @override
  Future<void> send(AppNotification notification, {List<String>? toUserIds}) async {
    try {
      final data = {
        'appId': _oneSignalAppId,
        'title': notification.title,
        'body': notification.body,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        if (notification.payload != null) 'payload': notification.payload,
        if (notification.imageUrl != null) 'imageUrl': notification.imageUrl,
        if (notification.launchUrl != null) 'launchUrl': notification.launchUrl,
        if (notification.deliveryTime != null)
          'deliveryTime': Timestamp.fromDate(notification.deliveryTime!)
        else if (notification.scheduleTime != null)
          'deliveryTime': Timestamp.fromDate(notification.scheduleTime!),
        if (toUserIds != null && toUserIds.isNotEmpty)
          'targetUserIds': toUserIds
        else
          'targetSegments': ['All'],
      };

      await FirebaseFirestore.instance
          .collection(FirestorePaths.notificationQueue)
          .add(data);
          
      printInfo('Notification queued successfully in Firestore.');

      // Hybrid approach: Trigger the Cloudflare Worker URL directly if set in environment
      final workerUrl = dotenv.env['CLOUDFLARE_WORKER_URL'];
      if (workerUrl != null && workerUrl.isNotEmpty) {
        printInfo('Triggering Cloudflare Worker proxy at: $workerUrl');
        final httpPayload = {
          'appId': _oneSignalAppId,
          'title': notification.title,
          'body': notification.body,
          if (notification.payload != null) 'payload': notification.payload,
          if (notification.imageUrl != null) 'imageUrl': notification.imageUrl,
          if (notification.launchUrl != null) 'launchUrl': notification.launchUrl,
          if (notification.deliveryTime != null)
            'deliveryTime': notification.deliveryTime!.toIso8601String()
          else if (notification.scheduleTime != null)
            'deliveryTime': notification.scheduleTime!.toIso8601String(),
          if (toUserIds != null && toUserIds.isNotEmpty)
            'targetUserIds': toUserIds
          else
            'targetSegments': ['All'],
        };

        final response = await http.post(
          Uri.parse(workerUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(httpPayload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          printInfo('Notification delivered instantly via Cloudflare Worker proxy.');
        } else {
          printError('Failed to trigger Cloudflare Worker proxy: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      printError('Error sending notification: $e');
    }
  }
}