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
  String get paypalLink => data['paypalLink'] as String? ?? 'FatihKantin';

  List<Map<String, dynamic>> get kantinProducts {
    final raw = data['kantinProducts'] as List<dynamic>?;
    if (raw == null) {
      return [
        {'name': 'Eis groß', 'price': 1.0},
        {'name': 'Eis klein', 'price': 0.5},
        {'name': 'Spezi', 'price': 1.0},
      ];
    }
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

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