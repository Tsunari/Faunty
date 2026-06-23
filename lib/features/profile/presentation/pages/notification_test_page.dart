import 'package:faunty/features/notifications/data/reminder_manager.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class NotificationTestPage extends ConsumerStatefulWidget {
  const NotificationTestPage({super.key});

  @override
  ConsumerState<NotificationTestPage> createState() =>
      _NotificationTestPageState();
}

class _NotificationTestPageState extends ConsumerState<NotificationTestPage> {
  final _delayController = TextEditingController(text: '2');
  bool _isLoading = false;

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  Future<void> _scheduleTest() async {
    final user = ref.read(userProvider).asData?.value;
    if (user == null) return;

    final minutes = int.tryParse(_delayController.text) ?? 2;

    setState(() => _isLoading = true);
    try {
      await ReminderManager().scheduleCateringTest(
        user,
        Duration(minutes: minutes),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test notification scheduled for $minutes minutes from now',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Notification Test Page', useModern: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule a test catering reminder notification. '
              'Close the app after scheduling to verify delivery.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _delayController,
              decoration: const InputDecoration(
                labelText: 'Delay (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _scheduleTest,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Schedule Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}