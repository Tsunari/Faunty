import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// A simple wrapper for OneSignal Web SDK using dart:js_interop.
/// This allows you to interact with OneSignal from your Dart code.
class OneSignalHelper {
  /// Initialization stub for web (initialized in index.html)
  static void initialize() {}

  /// Logs the user in with an external ID (e.g. Firebase UID).
  static void login(String externalId) {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        oneSignal.login(externalId.toJS);
      } catch (e) {
        print('Error calling OneSignal.login: $e');
      }
    });
  }

  /// Logs the user out.
  static void logout() {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        oneSignal.logout();
      } catch (e) {
        print('Error calling OneSignal.logout: $e');
      }
    });
  }

  /// Prompts the user for push notifications permission.
  static void requestPermission() {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        oneSignal.Notifications?.requestPermission();
      } catch (e) {
        print('Error calling OneSignal.requestPermission: $e');
      }
    });
  }

  /// Adds a tag to the user.
  static void addTag(String key, String value) {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        oneSignal.User?.addTag(key.toJS, value.toJS);
      } catch (e) {
        print('Error calling OneSignal.addTag: $e');
      }
    });
  }

  /// Removes a tag from the user.
  static void removeTag(String key) {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        oneSignal.User?.removeTag(key.toJS);
      } catch (e) {
        print('Error calling OneSignal.removeTag: $e');
      }
    });
  }

  /// Sets the subscription status (opt-in/opt-out).
  static void setSubscription(bool enable) {
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        return;
      }
      try {
        final user = oneSignal.User;
        if (user != null && !user.isUndefinedOrNull) {
          final subscription = user.PushSubscription;
          if (subscription != null && !subscription.isUndefinedOrNull) {
            if (enable) {
              subscription.optIn();
            } else {
              subscription.optOut();
            }
          }
        }
      } catch (e) {
        print('Error calling OneSignal.setSubscription: $e');
      }
    });
  }

  /// Checks if the user is subscribed (opted-in).
  static Future<bool> isSubscribed() {
    final completer = Completer<bool>();
    _push((OneSignalJS? oneSignal) {
      if (oneSignal == null || oneSignal.isUndefinedOrNull) {
        print('OneSignal is not initialized or null.');
        completer.complete(false);
        return;
      }
      try {
        final user = oneSignal.User;
        if (user != null && !user.isUndefinedOrNull) {
          final subscription = user.PushSubscription;
          if (subscription != null && !subscription.isUndefinedOrNull) {
            print('OneSignal Subscription: optedIn=${subscription.optedIn}, id=${subscription.id}, token=${subscription.token}');
            completer.complete(subscription.optedIn);
          } else {
            print('OneSignal: PushSubscription is null');
            completer.complete(false);
          }
        } else {
          print('OneSignal: User is null');
          completer.complete(false);
        }
      } catch (e) {
        print('Error checking subscription: $e');
        completer.complete(false);
      }
    });
    return completer.future;
  }

  /// Helper to push commands to OneSignalDeferred.
  static void _push(void Function(OneSignalJS?) callback) {
    final deferred = globalContext['OneSignalDeferred'];
    if (deferred != null) {
      (deferred as JSObject).callMethod('push'.toJS, callback.toJS);
    } else {
      print('OneSignalDeferred not found. Make sure the SDK script is in index.html');
    }
  }
}

/// JS Interop definitions for OneSignal SDK
@JS()
extension type OneSignalJS._(JSObject _) implements JSObject {
  external void login(JSString externalId);
  external void logout();
  external OneSignalSlidedown? get Slidedown;
  external OneSignalUser? get User;
  external OneSignalNotifications? get Notifications;
}

@JS()
extension type OneSignalNotifications._(JSObject _) implements JSObject {
  external void requestPermission();
}

@JS()
extension type OneSignalSlidedown._(JSObject _) implements JSObject {
  external void promptPush();
}

@JS()
extension type OneSignalUser._(JSObject _) implements JSObject {
  external void addTag(JSString key, JSString value);
  external void removeTag(JSString key);
  external OneSignalPushSubscription? get PushSubscription;
}

@JS()
extension type OneSignalPushSubscription._(JSObject _) implements JSObject {
  external void optIn();
  external void optOut();
  external bool get optedIn;
  external JSString? get id;
  external JSString? get token;
}
