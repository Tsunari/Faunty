import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firestore/attendance_firestore_service.dart';

final attendanceProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, placeId) {
  return AttendanceFirestoreService(placeId).getAttendanceStream();
});

final attendanceMetaProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, placeId) {
  return AttendanceFirestoreService(placeId).getAttendanceMetaStream();
});
