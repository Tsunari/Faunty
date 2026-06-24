import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/tracking/data/repositories/tracking_repository.dart';

part 'attendance_provider.g.dart';

@riverpod
Stream<Map<String, dynamic>> attendance(AttendanceRef ref, String placeId) {
  return ref.watch(trackingRepositoryProvider).getAttendanceService(placeId).getAttendanceStream();
}

@riverpod
Stream<Map<String, dynamic>> attendanceMeta(AttendanceMetaRef ref, String placeId) {
  return ref.watch(trackingRepositoryProvider).getAttendanceService(placeId).getAttendanceMetaStream();
}