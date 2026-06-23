/// Stub for non-web platforms
class OneSignalHelper {
  static void login(String externalId) {}
  static void logout() {}
  static void requestPermission() {}
  static void addTag(String key, String value) {}
  static void removeTag(String key) {}
  static void setSubscription(bool enable) {}
  static Future<bool> isSubscribed() async => false;
}
