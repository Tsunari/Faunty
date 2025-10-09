
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firestore/cleaning_firestore_service.dart';
import 'user_provider.dart';

final cleaningFirestoreServiceProvider = Provider<CleaningFirestoreService>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using CleaningFirestoreService');
  }
  return CleaningFirestoreService(user);
});

/// Provides the full cleaning data map (places and assignments)
final cleaningDataProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(cleaningFirestoreServiceProvider);
  return service.watchCleaning();
});

// Checks if all places are empty (no users assigned)
final placesEmptyProvider = Provider<bool>((ref) {
  final cleaningDoc = ref.watch(cleaningDataProvider).maybeWhen(
    data: (data) => data,
    orElse: () => {},
  );

  // cleaningDoc can be the full document ({'places': {...}, 'groups': {...}, ...})
  // or legacy: a plain places map. Prefer explicit 'places' key.
  final placesMap = (cleaningDoc['places'] is Map) ? Map<String, dynamic>.from(cleaningDoc['places'] as Map) : Map<String, dynamic>.from(cleaningDoc);
  if (placesMap.isEmpty) return true;
  final places = placesMap.entries.toList();
  return places.every((e) {
    final placeData = e.value as Map<String, dynamic>;
    final assigned = (placeData['assignees'] as List?)?.cast<String>() ?? [];
    return assigned.isEmpty;
  });
});