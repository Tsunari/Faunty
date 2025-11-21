import 'dart:io' show Platform;
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'token_management.dart';

/// Simple NotificationService wrapper for FCM initialization and handling.
class NotificationService {
	NotificationService._();

	static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

	// VAPID key used for web token requests. Keep a single source to avoid
	// generating different tokens by calling getToken with/without different keys.
	static const String _vapidKey = 'BFAfGKzxnVVxMbYsIJ3NXS4L4iHjRdFh4MGJvP7qq6jyT78WOjhVthqzBKjejvIN6Um_QVKUA5gm6r2oVjs_63M';

	// Broadcast stream controller to allow UI wrappers to listen for messages
	static final StreamController<RemoteMessage> _messageController = StreamController<RemoteMessage>.broadcast();

	/// Stream of incoming messages (foreground and opened messages).
	static Stream<RemoteMessage> get messages => _messageController.stream;

	/// Initialize FCM. If [requestPermissions] is true, will request permissions on iOS/web.
	static Future<void> init({bool requestPermissions = true}) async {
		// On web, enable auto init and we'll pass the VAPID key to getToken below
		if (kIsWeb) {
			try {
				await _messaging.getInitialMessage();
				await _messaging.setAutoInitEnabled(true);
			} catch (e) {
				if (kDebugMode) print('Web FCM init warning: $e');
			}
		}

		// Get and handle token
		_messaging.onTokenRefresh.listen((newToken) async {
			await _storeTokenIfAvailable(newToken);
		});

		// When a user signs in, attempt to fetch/store the token so the token
		// document can be associated with the user's uid. This uses
		// fetchTokenIfAllowed() so it won't trigger a browser permission prompt.
		FirebaseAuth.instance.authStateChanges().listen((user) async {
			if (user != null) {
				try {
					await fetchTokenIfAllowed();
				} catch (e) {
					if (kDebugMode) print('fetchTokenOnSignIn error: $e');
				}
			}
		});

		// Foreground message handler
		FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
			if (kDebugMode) print('Foreground message received: ${msg.messageId}');
			_messageController.add(msg);
		});

		// When the user opens a notification (background -> foreground or tap)
		FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
			if (kDebugMode) print('Message opened from background: ${msg.messageId}');
			_messageController.add(msg);
		});

	}

	/// Attempt to fetch the current FCM token and store it, but only when it's
	/// safe to do so (won't trigger a browser permission prompt).
	///
	/// On web this checks the current notification settings and only calls
	/// getToken() when the status is authorized or provisional. On mobile we
	/// fetch the token directly.
	static Future<String?> fetchTokenIfAllowed() async {
		try {
			if (kIsWeb) {
				final settings = await _messaging.getNotificationSettings();
				if (settings.authorizationStatus == AuthorizationStatus.authorized ||
					settings.authorizationStatus == AuthorizationStatus.provisional) {
					// safe to fetch token
					String? token;
					try {
						token = await _messaging.getToken(vapidKey: _vapidKey);
					} catch (e) {
						if (kDebugMode) print('getToken with vapidKey failed: $e');
						token = await _messaging.getToken();
					}
					if (token != null) await _storeTokenIfAvailable(token);
					return token;
				}
				// not authorized — do not call getToken to avoid prompting
				return null;
			} else {
				final token = await _messaging.getToken();
				if (token != null) await _storeTokenIfAvailable(token);
				return token;
			}
		} catch (e) {
			if (kDebugMode) print('fetchTokenIfAllowed error: $e');
			return null;
		}
		}

	/// Check permission & optionally request it.
	static Future<NotificationSettings> checkAndRequestPermission({bool requestIfNot = true}) async {
		final settings = await _messaging.getNotificationSettings();
		if (settings.authorizationStatus == AuthorizationStatus.notDetermined && requestIfNot) {
			final granted = await _messaging.requestPermission(alert: true, badge: true, sound: true);
			// If user granted permission, attempt to fetch & store token immediately
			if (granted.authorizationStatus == AuthorizationStatus.authorized ||
				granted.authorizationStatus == AuthorizationStatus.provisional) {
				try {
					await fetchTokenIfAllowed();
				} catch (e) {
					if (kDebugMode) print('fetch-token-after-permission failed: $e');
				}
			}
			return granted;
		}
		return settings;
	}

	static Future<void> _storeTokenIfAvailable(String token) async {
		// Get current user UID if available
		final uid = FirebaseAuth.instance.currentUser?.uid;
		final platform = _detectPlatform();
		final now = DateTime.now().toUtc();

		final tokenInfo = TokenInfo(
			token: token,
			uid: uid,
			platform: platform,
			createdAt: now,
			lastSeenAt: now,
		);

		await TokenManager.saveToken(tokenInfo);
	}

	static String _detectPlatform() {
		if (kIsWeb) return 'web';
		if (Platform.isAndroid) return 'android';
		if (Platform.isIOS) return 'ios';
		if (Platform.isMacOS) return 'macos';
		if (Platform.isWindows) return 'windows';
		if (Platform.isLinux) return 'linux';
		return 'unknown';
	}
}
