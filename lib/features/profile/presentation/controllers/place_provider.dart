import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/domain/entities/place_model.dart';
import 'package:faunty/features/profile/data/repositories/place_firestore_service.dart';

final placeListProvider = FutureProvider<List<PlaceModel>>((ref) async {
  return await PlaceFirestoreService.fetchPlaces();
});

final placeStreamProvider = StreamProvider<List<PlaceModel>>((ref) {
  return PlaceFirestoreService.placesStream();
});