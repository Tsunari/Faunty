import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/communication/data/repositories/communication_repository.dart';
import 'package:faunty/features/communication/data/repositories/survey_firestore_service.dart';

part 'survey_provider.g.dart';

@riverpod
Stream<List<Map<String, dynamic>>> survey(SurveyRef ref, String placeId) {
  return ref.watch(communicationRepositoryProvider).surveyStream(placeId);
}

@riverpod
SurveyFirestoreService surveyFirestoreService(SurveyFirestoreServiceRef ref, String placeId) {
  return SurveyFirestoreService(placeId);
}