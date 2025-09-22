import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firestore/catering_firestore_service.dart';
import 'user_provider.dart';

final cateringFirestoreServiceProvider = Provider<CateringFirestoreService>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using CateringFirestoreService');
  }
  return CateringFirestoreService(user);
});

final cateringWeekPlanProvider = StreamProvider<List<List<List<String>>>>((ref) {
  final service = ref.watch(cateringFirestoreServiceProvider);
  return service.watchWeekPlan();
});

final cateringUniformDaysProvider = StreamProvider<List<bool>>((ref) {
  final service = ref.watch(cateringFirestoreServiceProvider);
  return service.watchUniformDays();
});
