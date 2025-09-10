import 'package:faunty/components/role_gate.dart';
import 'package:faunty/firestore/globals_firestore_service.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/pages/more/about_page.dart';
import 'package:faunty/pages/more/account_page.dart';
import 'package:faunty/state_management/user_provider.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/globals_provider.dart';
import 'users_page.dart';
import '../../components/custom_chip.dart';
import 'settings_page.dart';
import 'package:faunty/components/language_dropdown.dart';
import 'package:faunty/pages/more/ui_test_page.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 80),
        // Hero image at the top
        Center(
          child: Hero(
            tag: 'logo',
            child: GestureDetector(
              onDoubleTap: () async {
                logout(context: context, ref: ref);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    child: Image(
                      image: AssetImage(
                        Theme.of(context).brightness == Brightness.light
                            ? 'assets/Logo.png'
                          : 'assets/LogoInverse.png'
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        // SwitchListTile(
        //   secondary: Icon(Icons.dark_mode_outlined, color: primaryColor),
        //   title: const Text('Dark Mode'),
        //   subtitle: const Text('Switch between light and dark mode'),
        //   value: darkMode,
        //   onChanged: (val) {
        //     setState(() => darkMode = val);
        //   },
        // ),
        RoleGate(
          minRole: UserRole.hoca,
          child: Consumer(
            builder: (context, ref, _) {
              final globalsAsync = ref.watch(globalsProvider);
              final userAsync = ref.watch(userProvider);
              final user = userAsync.asData?.value;
              return globalsAsync.when(
                loading: () => SwitchListTile(
                  secondary: const Icon(Icons.app_registration_outlined),
                  title: Text(
                    translation(context: context, 'Registration Mode'),
                  ),
                  value: false,
                  onChanged: null,
                ),
                error: (e, st) => ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Error loading registration mode'),
                  subtitle: Text(e.toString()),
                ),
                data: (globals) => SwitchListTile(
                  secondary: Icon(
                    Icons.app_registration_outlined,
                    color: primaryColor,
                  ),
                  title: Row(
                    children: [
                      Text(translation(context: context, 'Registration Mode')),
                      const SizedBox(width: 4),
                      CustomContainerChip(
                        label: globals.registrationMode
                            ? translation(context: context, 'Active')
                            : translation(context: context, 'Inactive'),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    translation(
                      context: context,
                      'Enable or disable registration',
                    ),
                  ),
                  value: globals.registrationMode,
                  onChanged: (val) async {
                    if (user == null) return;
                    final service = GlobalsFirestoreService(user.placeId);
                    await service.setGlobalField('registrationMode', val);
                  },
                ),
              );
            },
          ),
        ),
        RoleGate(minRole: UserRole.hoca, child: const Divider()),
        ListTile(
          leading: Icon(Icons.account_circle_outlined, color: primaryColor),
          title: Text(translation(context: context, 'Account')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AccountPage()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.group_outlined, color: primaryColor),
          title: Text(translation(context: context, 'Users')),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const UsersPage()));
          },
        ),
        ListTile(
          leading: Icon(Icons.language_outlined, color: primaryColor),
          title: Text(translation(context: context, 'Language')),
          trailing: LanguageDropdown(
            borderColor: primaryColor.withOpacity(0.5),
          ),
        ),
        ListTile(
          leading: Icon(Icons.extension_outlined, color: primaryColor),
          title: Row(
            children: [
              Text(translation(context: context, 'Tools')),
              const SizedBox(width: 4),
              CustomContainerChip(
                label: translation(context: context, 'Under Construction'),
              ),
            ],
          ),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.settings_outlined, color: primaryColor),
          title: Text(translation(context: context, 'Settings')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.info_outline, color: primaryColor),
          title: Text(translation(context: context, 'About')),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const AboutPage()));
          },
        ),
        ListTile(
          leading: Icon(Icons.feedback_outlined, color: primaryColor),
          title: Row(
            children: [
              Text(translation(context: context, 'Feedback')),
              const SizedBox(width: 4),
              CustomContainerChip(
                label: translation(context: context, 'Under Construction'),
              ),
            ],
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.help_outline, color: primaryColor),
          title: Row(
            children: [
              Text(translation(context: context, 'Help')),
              const SizedBox(width: 4),
              CustomContainerChip(
                label: translation(context: context, 'Under Construction'),
              ),
            ],
          ),
          onTap: () {},
        ),
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: primaryColor),
            title: Text(translation(context: context, 'UI Test Page')),
            subtitle: Text(translation(context: context, 'Debug only')),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UiTestPage()),
              );
            },
          ),
      ],
    );
  }
}
