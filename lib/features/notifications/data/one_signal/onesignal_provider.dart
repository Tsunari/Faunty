import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/core/utils/logging.dart';
import 'package:flutter/foundation.dart';
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
    } catch (e) {
      printError('Error queuing notification: $e');
    }
  }
}