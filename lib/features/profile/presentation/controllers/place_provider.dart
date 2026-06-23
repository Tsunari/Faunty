import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/profile/domain/entities/place_model.dart';
import 'package:faunty/features/profile/data/repositories/profile_repository.dart';

part 'place_provider.g.dart';

@riverpod
Future<List<PlaceModel>> placeList(PlaceListRef ref) async {
  return await ref.watch(profileRepositoryProvider).fetchPlaces();
}

@riverpod
Stream<List<PlaceModel>> placeStream(PlaceStreamRef ref) {
  return ref.watch(profileRepositoryProvider).placesStream();
}