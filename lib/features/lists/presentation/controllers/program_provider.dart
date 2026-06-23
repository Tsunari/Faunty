import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/lists/data/repositories/program_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/lists_repository.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

part 'program_provider.g.dart';

@riverpod
ProgramFirestoreService programFirestoreService(ProgramFirestoreServiceRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    throw Exception('User must be loaded before using ProgramFirestoreService');
  }
  return ref.watch(listsRepositoryProvider).getProgramService(user);
}

@riverpod
Stream<Map<String, List<Map<String, String>>>> weekProgram(WeekProgramRef ref) {
  return ref.watch(programFirestoreServiceProvider).watchWeekProgram();
}

@riverpod
Future<Map<String, Map<String, List<Map<String, String>>>>> programTemplates(ProgramTemplatesRef ref) {
  return ref.watch(programFirestoreServiceProvider).getTemplates();
}

@riverpod
Future<void> saveProgramTemplate(SaveProgramTemplateRef ref, MapEntry<String, Map<String, List<Map<String, String>>>> entry) {
  return ref.watch(programFirestoreServiceProvider).setTemplate(entry.key, entry.value);
}

@riverpod
Future<void> deleteProgramTemplate(DeleteProgramTemplateRef ref, String templateName) {
  return ref.watch(programFirestoreServiceProvider).deleteTemplate(templateName);
}