import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/features/notifications/data/notification_manager.dart';
import 'package:faunty/features/notifications/data/types/custom_notification.dart';
import 'package:faunty/features/notifications/presentation/controllers/notification_permission_provider.dart';

Future<void> showOneSignalDialog(BuildContext context, WidgetRef ref) async {
  await showDialog(
    context: context,
    builder: (ctx) => const _OneSignalDialogContent(),
  );
}

class _OneSignalDialogContent extends ConsumerStatefulWidget {
  const _OneSignalDialogContent();

  @override
  ConsumerState<_OneSignalDialogContent> createState() => _OneSignalDialogContentState();
}

class _OneSignalDialogContentState extends ConsumerState<_OneSignalDialogContent> {
  final _titleController = TextEditingController(text: 'Test Notification');
  final _bodyController = TextEditingController(text: 'This is a custom test message.');
  final _imageUrlController = TextEditingController();
  final _launchUrlController = TextEditingController();
  final _payloadController = TextEditingController(text: '{"type": "test"}');
  String? _selectedUserId;
  bool _isSending = false;

  bool get _hasApiKey => (dotenv.env['ONESIGNAL_REST_API_KEY']?.isNotEmpty ?? false) && dotenv.env['ONESIGNAL_REST_API_KEY'] != 'YOUR_REST_API_KEY_HERE';

  final Map<String, String> _predefinedImages = {
    'None': '',
    'Logo': 'assets/Logo.png',
    'Logo Inverse': 'assets/LogoInverse.png',
    'Random (Picsum)': 'https://picsum.photos/200',
  };

  final Map<String, String> _predefinedUrls = {
    'None': '',
    'Home': '/',
    'Kantin': '/kantin',
    'Lists': '/lists',
    'Communication': '/communication',
    'Tracking': '/tracking',
    'More': '/more',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _launchUrlController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    setState(() => _isSending = true);
    try {
      Map<String, dynamic>? payload;
      if (_payloadController.text.isNotEmpty) {
        try {
          payload = jsonDecode(_payloadController.text);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid JSON payload: $e')),
          );
          setState(() => _isSending = false);
          return;
        }
      }

      final notification = CustomNotification(
        title: _titleController.text,
        body: _bodyController.text,
        payload: payload,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        launchUrl: _launchUrlController.text.isEmpty ? null : _launchUrlController.text,
      );

      if (kDebugMode) {
        print('--- Sending Notification ---');
        print('Title: ${notification.title}');
        print('Body: ${notification.body}');
        print('Payload: ${notification.payload}');
        print('Image URL: ${notification.imageUrl}');
        print('Launch URL: ${notification.launchUrl}');
        print('----------------------------');
      }

      await NotificationManager().send(
        notification,
        toUserIds: _selectedUserId != null ? [_selectedUserId!] : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translation(context: context, 'Notification sent!'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildStatusChip({
    required String label,
    required bool isOk,
    required String okText,
    required String errorText,
  }) {
    return Chip(
      label: Text(
        '$label: ${isOk ? okText : errorText}',
        style: TextStyle(
          color: isOk ? Colors.green[900] : Colors.red[900],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isOk ? Colors.green[100] : Colors.red[100],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersByCurrentPlaceProvider);
    final permissionState = ref.watch(notificationPermissionProvider);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(translation(context: context, 'OneSignal Debug')),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildStatusChip(
                label: 'API Key',
                isOk: _hasApiKey,
                okText: 'Present',
                errorText: 'Missing',
              ),
              _buildStatusChip(
                label: 'Permission',
                isOk: permissionState.permissionStatus == 'granted',
                okText: permissionState.permissionStatus,
                errorText: permissionState.permissionStatus,
              ),
              _buildStatusChip(
                label: 'Subscribed',
                isOk: permissionState.isSubscribed,
                okText: 'Yes',
                errorText: 'No',
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_hasApiKey)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ONESIGNAL_REST_API_KEY is missing in .env. Sending will fail.',
                        style: TextStyle(color: Colors.red[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            usersAsync.when(
              data: (users) {
                final allOptions = [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(translation(context: context, 'All Users')),
                  ),
                  ...users.map((user) => DropdownMenuItem<String?>(
                    value: user.uid,
                    child: Text('${user.firstName} ${user.lastName}'),
                  )),
                ];
                return DropdownButtonFormField<String?>(
                  value: _selectedUserId,
                  decoration: InputDecoration(labelText: translation(context: context, 'Target User')),
                  items: allOptions,
                  onChanged: (value) => setState(() => _selectedUserId = value),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: translation(context: context, 'Title')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: translation(context: context, 'Body')),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(labelText: translation(context: context, 'Image URL (Optional)')),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: translation(context: context, 'Select predefined image'),
                  onSelected: (value) {
                    if (value.startsWith('assets/')) {
                      // Construct absolute URL for local assets
                      final origin = Uri.base.origin;
                      // Ensure no double slash if origin ends with /
                      final cleanOrigin = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
                      _imageUrlController.text = '$cleanOrigin/$value';
                    } else {
                      _imageUrlController.text = value;
                    }
                  },
                  itemBuilder: (context) => _predefinedImages.entries.map((e) => PopupMenuItem(
                    value: e.value,
                    child: Text(e.key),
                  )).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _launchUrlController,
                    decoration: InputDecoration(labelText: translation(context: context, 'Launch URL (Optional)')),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: translation(context: context, 'Select predefined URL'),
                  onSelected: (value) {
                     if (value.startsWith('/')) {
                      // Construct absolute URL for local routes
                      final origin = Uri.base.origin;
                      final cleanOrigin = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
                      // Remove leading slash from value to avoid double slash
                      final cleanValue = value.startsWith('/') ? value.substring(1) : value;
                      _launchUrlController.text = '$cleanOrigin/$cleanValue';
                    } else {
                      _launchUrlController.text = value;
                    }
                  },
                  itemBuilder: (context) => _predefinedUrls.entries.map((e) => PopupMenuItem(
                    value: e.value,
                    child: Text(e.key),
                  )).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payloadController,
              decoration: InputDecoration(labelText: translation(context: context, 'JSON Payload (Optional)')),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(translation(context: context, 'Close')),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendNotification,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(translation(context: context, 'Send')),
        ),
      ],
    );
  }
}