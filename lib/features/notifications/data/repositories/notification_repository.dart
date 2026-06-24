import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/core/network/firebase_providers.dart';
import 'package:faunty/features/notifications/data/app_notification.dart';
import 'package:faunty/core/constants/firestore_paths.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  static const String _oneSignalAppId = 'f2a525de-b733-4e92-9494-dff5eae29756';

  NotificationRepository(this._firestore);

  Future<void> enqueueNotification(AppNotification notification, {List<String>? toUserIds}) async {
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

    await _firestore
        .collection(FirestorePaths.notificationQueue)
        .add(data);
  }
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
}
