import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/lists/data/repositories/catering_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/lists_repository.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

part 'catering_provider.g.dart';

@riverpod
CateringFirestoreService cateringFirestoreService(CateringFirestoreServiceRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using CateringFirestoreService');
  }
  return ref.watch(listsRepositoryProvider).getCateringService(user);
}

@riverpod
Stream<List<List<List<String>>>> cateringWeekPlan(CateringWeekPlanRef ref) {
  return ref.watch(cateringFirestoreServiceProvider).watchWeekPlan();
}

@riverpod
Stream<List<bool>> cateringUniformDays(CateringUniformDaysRef ref) {
  return ref.watch(cateringFirestoreServiceProvider).watchUniformDays();
}

@riverpod
Stream<Map<String, String>> cateringSlotNames(CateringSlotNamesRef ref) {
  return ref.watch(cateringFirestoreServiceProvider).watchSlotNames();
}