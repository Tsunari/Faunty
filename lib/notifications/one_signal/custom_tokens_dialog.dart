import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tools/translation_helper.dart';
import '../notification_manager.dart';
import '../types/test_notification.dart';

Future<void> showOneSignalDialog(BuildContext context, WidgetRef ref) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(translation(context: context, 'OneSignal Test')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text(translation(context: context, 'OneSignal Provider is active.')),
          // const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              NotificationManager().send(TestNotification());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(translation(context: context, 'Test notification sent'))),
              );
            },
            child: const Text('Send Test Notification'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(translation(context: context, 'Close')),
        ),
      ],
    ),
  );
}
