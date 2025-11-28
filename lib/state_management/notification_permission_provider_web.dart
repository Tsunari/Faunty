import 'package:faunty/helper/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import '../notifications/notification_manager.dart';
import '../notifications/one_signal/onesignal_bridge.dart';

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
  NotificationPermissionNotifier() : super(NotificationState(permissionStatus: 'default', isSubscribed: false, isLoading: true)) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    // Only set loading if not already loading (to avoid flickering if called multiple times)
    // But here we want to show loading for the initial check
    // state = state.copyWith(isLoading: true); 
    
    String status = 'unknown';
    bool subscribed = false;

    if (kIsWeb) {
      // Access window.Notification.permission
      final notification = globalContext['Notification'];
      if (notification != null) {
        final permission = (notification as JSObject).getProperty('permission'.toJS);
        status = (permission as JSString).toDart;
      } else {
        status = 'unsupported';
      }
      
      // Check OneSignal subscription status
      subscribed = await OneSignalHelper.isSubscribed();
      printInfo('Notification Check: status=$status, subscribed=$subscribed');
    } else {
      // TODO: Implement for mobile if needed
      status = 'unknown';
    }
    
    if (mounted) {
      state = NotificationState(
        permissionStatus: status,
        isSubscribed: subscribed,
        isLoading: false,
      );
    }
  }

  Future<void> toggleSubscription(bool enable) async {
    state = state.copyWith(isLoading: true);
    try {
      if (enable) {
        // If enabling, we might need to request permission first if default
        if (state.permissionStatus == 'default') {
          await requestPermission();
          // After request, if granted, we opt-in
          if (state.permissionStatus == 'granted') {
             OneSignalHelper.setSubscription(true);
             // Re-check state
             await checkPermission();
          }
        } else if (state.permissionStatus == 'granted') {
          // Just opt-in
          OneSignalHelper.setSubscription(true);
          // Optimistic update or wait?
          // Let's wait a bit or just re-check
          await Future.delayed(const Duration(milliseconds: 500));
          await checkPermission();
        }
        // If denied, we can't do anything programmatically to enable, UI handles the alert
      } else {
        // Disabling: just opt-out
        OneSignalHelper.setSubscription(false);
        await Future.delayed(const Duration(milliseconds: 500));
        await checkPermission();
      }
    } finally {
      // Ensure loading is turned off if checkPermission didn't do it (e.g. early return)
      // checkPermission sets it to false, so we are good.
      if (mounted && state.isLoading) {
         state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> requestPermission() async {
    await NotificationManager().requestPermission();
    // Poll for permission change as the request is async and we can't easily await the JS promise through the bridge
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final oldState = state;
      await checkPermission();
      if (!mounted) return;
      if (state.permissionStatus != oldState.permissionStatus && state.permissionStatus != 'default') break;
    }
  }
}
