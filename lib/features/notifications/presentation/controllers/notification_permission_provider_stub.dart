import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/notifications/data/one_signal/onesignal_bridge.dart';

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
  NotificationPermissionNotifier()
      : super(NotificationState(permissionStatus: 'default', isSubscribed: false, isLoading: true)) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final hasSubscribed = await OneSignalHelper.isSubscribed();
    final status = hasSubscribed ? 'granted' : 'default';
    if (mounted) {
      state = NotificationState(
        permissionStatus: status,
        isSubscribed: hasSubscribed,
        isLoading: false,
      );
    }
  }

  Future<void> toggleSubscription(bool enable) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      OneSignalHelper.setSubscription(enable);
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermission();
    } finally {
      if (mounted && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> requestPermission() async {
    OneSignalHelper.requestPermission();
    await Future.delayed(const Duration(milliseconds: 1000));
    await checkPermission();
  }
}

