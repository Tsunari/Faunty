import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/profile/data/repositories/profile_repository.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

part 'globals_provider.g.dart';

class GlobalsState {
  final Map<String, dynamic> data;
  const GlobalsState(this.data);

  bool get registrationMode => data['registrationMode'] as bool? ?? false;
  bool get cateringReminderEnabled =>
      data['cateringReminderEnabled'] as bool? ?? true;

  GlobalsState copyWith(Map<String, dynamic> newData) =>
      GlobalsState({...data, ...newData});
}

@riverpod
Stream<GlobalsState> globals(GlobalsRef ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return Stream.value(const GlobalsState({}));
  }
  final service = ref.watch(profileRepositoryProvider).getGlobalsService(user.placeId);
  return service.globalsStream().map((data) => GlobalsState(data));
}