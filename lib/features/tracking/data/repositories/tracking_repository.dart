import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/core/network/firebase_providers.dart';
import 'package:faunty/features/tracking/data/repositories/attendance_firestore_service.dart';
import 'package:faunty/features/tracking/data/repositories/kantin_firestore_service.dart';

part 'tracking_repository.g.dart';

class TrackingRepository {
  final FirebaseFirestore _firestore;

  TrackingRepository(this._firestore);

  AttendanceFirestoreService getAttendanceService(String placeId) =>
      AttendanceFirestoreService(placeId);

  KantinFirestoreService getKantinService(String placeId) =>
      KantinFirestoreService(placeId);
}

@riverpod
TrackingRepository trackingRepository(TrackingRepositoryRef ref) {
  return TrackingRepository(ref.watch(firestoreProvider));
}
