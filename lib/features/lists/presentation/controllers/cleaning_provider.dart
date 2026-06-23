import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/lists/data/repositories/cleaning_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/lists_repository.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

part 'cleaning_provider.g.dart';

@riverpod
CleaningFirestoreService cleaningFirestoreService(CleaningFirestoreServiceRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using CleaningFirestoreService');
  }
  return ref.watch(listsRepositoryProvider).getCleaningService(user);
}

@riverpod
Stream<Map<String, dynamic>> cleaningData(CleaningDataRef ref) {
  return ref.watch(cleaningFirestoreServiceProvider).watchCleaning();
}

@riverpod
bool placesEmpty(PlacesEmptyRef ref) {
  final cleaningDoc = ref.watch(cleaningDataProvider).maybeWhen(
    data: (data) => data,
    orElse: () => {},
  );

  final placesMap = (cleaningDoc['places'] is Map)
      ? Map<String, dynamic>.from(cleaningDoc['places'] as Map)
      : Map<String, dynamic>.from(cleaningDoc);
  if (placesMap.isEmpty) return true;
  final places = placesMap.entries.toList();
  return places.every((e) {
    final placeData = e.value as Map<String, dynamic>;
    final assigned = (placeData['assignees'] as List?)?.cast<String>() ?? [];
    return assigned.isEmpty;
  });
}