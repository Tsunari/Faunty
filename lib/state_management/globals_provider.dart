import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/firestore/globals_firestore_service.dart';
import 'user_provider.dart';

class GlobalsState {
  final Map<String, dynamic> data;
  const GlobalsState(this.data);

  bool get registrationMode => data['registrationMode'] as bool? ?? false;
  bool get cateringReminderEnabled =>
      data['cateringReminderEnabled'] as bool? ?? true;
  // Add more getters for other globals as needed

  GlobalsState copyWith(Map<String, dynamic> newData) =>
      GlobalsState({...data, ...newData});
}

final globalsProvider = StreamProvider<GlobalsState>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return Stream.value(const GlobalsState({}));
  }
  final service = GlobalsFirestoreService(user.placeId);
  return service.globalsStream().map((data) => GlobalsState(data));
});
