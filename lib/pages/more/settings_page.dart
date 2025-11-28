import 'package:faunty/components/language_dropdown.dart';
import 'package:faunty/components/theme_cards_selector.dart';
import 'package:faunty/components/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tools/translation_helper.dart';
import 'package:faunty/state_management/theme_provider.dart';
import '../../state_management/notification_permission_provider.dart';
import 'package:faunty/components/role_gate.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/state_management/globals_provider.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/firestore/globals_firestore_service.dart';
import 'package:faunty/state_management/developer_mode_provider.dart';
import 'package:faunty/pages/more/notification_test_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final notificationState = ref.watch(notificationPermissionProvider);
    Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(translation(context: context, 'Settings'))),
      body: themeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading theme: $e')),
        data: (themeMode) => ListView(
          children: [
            ThemeSelector(borderColor: primaryColor),
            const SizedBox(height: 16),
            ThemeCardsSelector(borderColor: primaryColor),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: Icon(Icons.language, color: primaryColor),
              title: Text(translation(context: context, 'Language')),
              subtitle: Text(translation(context: context, 'Choose app language.')),
              trailing: LanguageDropdown(borderColor: primaryColor.withOpacity(0.5)),
            ),
            const Divider(),
            SwitchListTile(
              secondary: notificationState.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.notifications, color: primaryColor),
              title: Text(translation(context: context, 'Notifications')),
              subtitle: Text(
                notificationState.isLoading
                    ? translation(context: context, 'Loading...')
                    : notificationState.permissionStatus == 'denied'
                        ? translation(context: context, 'Blocked - Enable in browser settings')
                        : notificationState.isEnabled
                            ? translation(context: context, 'Enabled')
                            : translation(context: context, 'Disabled'),
              ),
              value: notificationState.isEnabled,
              onChanged: notificationState.isLoading ? null : (value) {
                if (notificationState.permissionStatus == 'denied' && value) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(translation(context: context, 'Notifications Blocked')),
                      content: Text(translation(context: context, 'Please enable notifications for this site in your browser settings (click the lock icon in the address bar).')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(translation(context: context, 'OK')),
                        ),
                      ],
                    ),
                  );
                } else {
                  ref.read(notificationPermissionProvider.notifier).toggleSubscription(value);
                }
              },
            ),
            const Divider(),
            // Manage Notifications (Baskan+)
            RoleGate(
              minRole: UserRole.baskan,
              child: Consumer(
                builder: (context, ref, _) {
                  final globalsAsync = ref.watch(globalsProvider);
                  final userAsync = ref.watch(userProvider);
                  final user = userAsync.asData?.value;

                  return globalsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (globals) => ExpansionTile(
                      shape: const Border(),
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: primaryColor,
                      ),
                      title: Text(
                        translation(context: context, 'Manage Notifications'),
                      ),
                      children: [
                        SwitchListTile(
                          title: Text(
                            translation(context: context, 'Catering Reminder'),
                          ),
                          subtitle: Text(
                            translation(
                              context: context,
                              'Daily 10 PM check for tomorrow',
                            ),
                          ),
                          value: globals.cateringReminderEnabled,
                          onChanged: (val) async {
                            if (user == null) return;
                            final service = GlobalsFirestoreService(
                              user.placeId,
                            );
                            await service.setGlobalField(
                              'cateringReminderEnabled',
                              val,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Developer Mode (Superuser)
            RoleGate(
              minRole: UserRole.superuser,
              child: Consumer(
                builder: (context, ref, _) {
                  final isDevMode = ref.watch(developerModeProvider);
                  return Column(
                    children: [
                      const Divider(),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.developer_mode,
                          color: primaryColor,
                        ),
                        title: const Text('Developer Mode'),
                        value: isDevMode,
                        onChanged: (val) {
                          ref.read(developerModeProvider.notifier).toggle(val);
                        },
                      ),
                      if (isDevMode)
                        ListTile(
                          leading: Icon(
                            Icons.bug_report_outlined,
                            color: primaryColor,
                          ),
                          title: const Text('Notification Test Page'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationTestPage(),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
