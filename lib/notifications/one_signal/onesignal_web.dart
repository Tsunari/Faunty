import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// A simple wrapper for OneSignal Web SDK using dart:js_interop.
/// This allows you to interact with OneSignal from your Dart code.
class OneSignalHelper {
  /// Logs the user in with an external ID (e.g. Firebase UID).
  static void login(String externalId) {
    _push((OneSignalJS oneSignal) {
      oneSignal.login(externalId.toJS);
    });
  }

  /// Logs the user out.
  static void logout() {
    _push((OneSignalJS oneSignal) {
      oneSignal.logout();
    });
  }

  /// Prompts the user for push notifications permission.
  static void showNativePrompt() {
    _push((OneSignalJS oneSignal) {
      oneSignal.Slidedown.promptPush();
    });
  }

  /// Adds a tag to the user.
  static void addTag(String key, String value) {
    _push((OneSignalJS oneSignal) {
      oneSignal.User.addTag(key.toJS, value.toJS);
    });
  }

  /// Removes a tag from the user.
  static void removeTag(String key) {
    _push((OneSignalJS oneSignal) {
      oneSignal.User.removeTag(key.toJS);
    });
  }

  /// Helper to push commands to OneSignalDeferred.
  static void _push(void Function(OneSignalJS) callback) {
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
  external OneSignalSlidedown get Slidedown;
  external OneSignalUser get User;
}

@JS()
extension type OneSignalSlidedown._(JSObject _) implements JSObject {
  external void promptPush();
}

@JS()
extension type OneSignalUser._(JSObject _) implements JSObject {
  external void addTag(JSString key, JSString value);
  external void removeTag(JSString key);
}
