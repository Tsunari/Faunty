import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/communication/data/repositories/survey_firestore_service.dart';

// Provider to watch the survey stream for a given placeId
final surveyProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, placeId) {
  final service = SurveyFirestoreService(placeId);
  return service.surveyStream();
});

final surveyFirestoreServiceProvider = Provider.family<SurveyFirestoreService, String>((ref, placeId) {
  return SurveyFirestoreService(placeId);
});