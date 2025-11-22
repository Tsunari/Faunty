import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationState {
  final String permissionStatus; // 'granted', 'denied', 'default', 'unsupported', 'unknown'
  final bool isSubscribed;
  final bool isLoading;

  NotificationState({
    required this.permissionStatus,
    required this.isSubscribed,
    this.isLoading = false,
  });

  NotificationState copyWith({
    String? permissionStatus,
    bool? isSubscribed,
    bool? isLoading,
  }) {
    return NotificationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isEnabled => permissionStatus == 'granted' && isSubscribed;
}

final notificationPermissionProvider = StateNotifierProvider.autoDispose<NotificationPermissionNotifier, NotificationState>((ref) {
  return NotificationPermissionNotifier();
});

class NotificationPermissionNotifier extends StateNotifier<NotificationState> {
  NotificationPermissionNotifier() : super(NotificationState(permissionStatus: 'default', isSubscribed: false, isLoading: true));

  Future<void> checkPermission() async {}
  Future<void> toggleSubscription(bool enable) async {}
  Future<void> requestPermission() async {}
}
