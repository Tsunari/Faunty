import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/lists/data/repositories/program_firestore_service.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

final programFirestoreServiceProvider = Provider<ProgramFirestoreService>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using ProgramFirestoreService');
  }
  return ProgramFirestoreService(user);
});

final weekProgramProvider = StreamProvider<Map<String, List<Map<String, String>>>>((ref) {
  final service = ref.watch(programFirestoreServiceProvider);
  return service.watchWeekProgram();
});

final programTemplatesProvider = FutureProvider<Map<String, Map<String, List<Map<String, String>>>>>((ref) {
  final service = ref.watch(programFirestoreServiceProvider);
  return service.getTemplates();
});

final saveProgramTemplateProvider = FutureProvider.family<void, MapEntry<String, Map<String, List<Map<String, String>>>>>((ref, entry) async {
  final service = ref.watch(programFirestoreServiceProvider);
  await service.setTemplate(entry.key, entry.value);
});

final deleteProgramTemplateProvider = FutureProvider.family<void, String>((ref, name) async {
  final service = ref.watch(programFirestoreServiceProvider);
  await service.deleteTemplate(name);
});