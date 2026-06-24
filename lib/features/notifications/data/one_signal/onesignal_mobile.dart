import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalHelper {
  static const String _appId = 'f2a525de-b733-4e92-9494-dff5eae29756';

  static void initialize() {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);
  }

  static void login(String externalId) {
    OneSignal.login(externalId);
  }

  static void logout() {
    OneSignal.logout();
  }

  static void requestPermission() {
    OneSignal.Notifications.requestPermission(true);
  }

  static void addTag(String key, String value) {
    OneSignal.User.addTagWithKey(key, value);
  }

  static void removeTag(String key) {
    OneSignal.User.removeTag(key);
  }

  static void setSubscription(bool enable) {
    if (enable) {
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
  }

  static Future<bool> isSubscribed() async {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }
}
