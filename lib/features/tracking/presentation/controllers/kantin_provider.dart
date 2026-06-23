import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/tracking/data/repositories/kantin_firestore_service.dart';

/// Provider to watch the kantin stream for a given placeId
final kantinProvider = StreamProvider.family<Map<String, double>, String>((ref, placeId) {
  final service = KantinFirestoreService(placeId);
  return service.kantinStream();
});

/// Example usage:
/// ref.watch(kantinProvider(placeId))