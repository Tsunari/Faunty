import 'package:shared_preferences/shared_preferences.dart';

const String _kTitleKey = 'faunty.testNotification.title';
const String _kBodyKey = 'faunty.testNotification.body';

// Use the newer async API directly. Create a single instance and reuse it.
final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

Future<String?> getTestNotificationTitle() async {
  return await _asyncPrefs.getString(_kTitleKey);
}

Future<String?> getTestNotificationBody() async {
  return await _asyncPrefs.getString(_kBodyKey);
}

Future<void> setTestNotificationTitle(String title) async {
  await _asyncPrefs.setString(_kTitleKey, title);
}

Future<void> setTestNotificationBody(String body) async {
  await _asyncPrefs.setString(_kBodyKey, body);
}
