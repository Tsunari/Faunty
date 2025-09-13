import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:faunty/tools/translation_helper.dart';
import '../components/custom_snackbar.dart';

/// Widget that wraps the app and shows an in-app banner / snackbar when a
/// foreground notification arrives. Use this by wrapping your root app widget
/// with `ForegroundNotificationWrapper(child: Faunty())`.
class ForegroundNotificationWrapper extends StatefulWidget {
  final Widget child;

  const ForegroundNotificationWrapper({super.key, required this.child});

  @override
  State<ForegroundNotificationWrapper> createState() => _ForegroundNotificationWrapperState();
}

class _ForegroundNotificationWrapperState extends State<ForegroundNotificationWrapper> {
  late final Stream<RemoteMessage> _onMessageStream;
  late final Stream<RemoteMessage> _onMessageOpenedStream;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  @override
  void initState() {
    super.initState();
    _onMessageStream = FirebaseMessaging.onMessage;
    _onMessageOpenedStream = FirebaseMessaging.onMessageOpenedApp;

    // Foreground messages: show an in-app banner/snackbar
    _onMessageSub = _onMessageStream.listen((msg) {
      if (kDebugMode) print('ForegroundNotificationWrapper.onMessage: ${msg.messageId}');
      if (!mounted) return; // avoid using context after dispose
      _showNotification(msg, openedFromAction: false);
    });

    // When user taps a notification (app in background -> foreground): show UI
    _onOpenedSub = _onMessageOpenedStream.listen((msg) {
      if (kDebugMode) print('ForegroundNotificationWrapper.onMessageOpenedApp: ${msg.messageId}');
      if (!mounted) return;
      _showNotification(msg, openedFromAction: true);
    });

    // Also check if app was launched from a notification (cold start)
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        if (kDebugMode) print('ForegroundNotificationWrapper.initialMessage: ${msg.messageId}');
        // Delay slightly so UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showNotification(msg, openedFromAction: true);
        });
      }
    }).catchError((e) {
      if (kDebugMode) print('getInitialMessage error: $e');
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    super.dispose();
  }

  void _showNotification(RemoteMessage msg, {required bool openedFromAction}) {
    try {
      final title = msg.notification?.title ?? msg.data['title'] ?? '';
      final body = msg.notification?.body ?? msg.data['body'] ?? '';

      // Prefer a MaterialBanner for a visible, tappable UI.
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (body.isNotEmpty) Text(body),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => messenger.clearMaterialBanners(),
                child: Text(translation(context: context, 'Dismiss')),
              ),
              TextButton(
                onPressed: () {
                  messenger.clearMaterialBanners();
                  showCustomSnackBar(context, translation(context: context, 'Notification opened'));
                },
                child: Text(translation(context: context, 'Open')),
              ),
            ],
          ),
        );
        Future.delayed(const Duration(seconds: 5), () {
          messenger.clearMaterialBanners();
        });
        return;
      }

      // Overlay fallback if no ScaffoldMessenger is present.
      if (!mounted) return;
      final overlay = Overlay.of(context);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => Positioned(
          top: MediaQuery.of(ctx).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(ctx).colorScheme.surface),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (body.isNotEmpty) Text(body),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      entry.remove();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      var inserted = false;
      try {
        overlay.insert(entry);
        inserted = true;
      } catch (e) {
        if (kDebugMode) print('Overlay insert failed: $e');
      }
      if (inserted) {
        Future.delayed(const Duration(seconds: 4), () {
          try {
            entry.remove();
          } catch (_) {}
        });
        return;
      }

      // Last resort: snackbar helper (may be no-op if no messenger)
      showCustomSnackBar(context, '${title.isNotEmpty ? '$title — ' : ''}$body');
    } catch (e) {
      if (kDebugMode) print('Error showing foreground notification UI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
