import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/tracking/data/repositories/tracking_repository.dart';

part 'kantin_provider.g.dart';

@riverpod
Stream<Map<String, double>> kantin(KantinRef ref, String placeId) {
  return ref.watch(trackingRepositoryProvider).getKantinService(placeId).kantinStream();
}