import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/features/profile/data/repositories/globals_firestore_service.dart';
import 'package:faunty/globals.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/profile/presentation/pages/about_page.dart';
import 'package:faunty/features/profile/presentation/pages/account_page.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/presentation/controllers/globals_provider.dart';
import 'package:faunty/features/profile/presentation/pages/users_page.dart';
import 'package:faunty/core/widgets/custom_chip.dart';
import 'package:faunty/features/profile/presentation/pages/settings_page.dart';
import 'package:faunty/core/widgets/language_dropdown.dart';
import 'package:faunty/features/profile/presentation/pages/ui_test_page.dart';
import 'package:faunty/features/profile/presentation/pages/feedback/feedback_page.dart';
import 'package:faunty/features/profile/presentation/pages/tools/tools_page.dart';
import 'package:faunty/core/widgets/glass_container.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    // Helper to build grouped card sections for settings
    Widget buildSectionCard(List<Widget> children) {
      return GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.zero,
        child: Column(
          children: children,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 32),
            
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                            width: 1.5,
                          ),
                        ),
                        child: SizedBox(
                          height: 90,
                          width: 90,
                          child: Image(
                            image: AssetImage(
                              theme.brightness == Brightness.light
                                  ? 'assets/Logo.png'
                                  : 'assets/LogoInverse.png',
                            ),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        translation(context: context, 'Faunty'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SECTION 1: Admin Actions (Registration Mode)
            RoleGate(
              minRole: UserRole.hoca,
              child: Consumer(
                builder: (context, ref, _) {
                  final globalsAsync = ref.watch(globalsProvider);
                  final userAsync = ref.watch(userProvider);
                  final user = userAsync.asData?.value;
                  
                  return buildSectionCard([
                    globalsAsync.when(
                      loading: () => SwitchListTile(
                        secondary: const Icon(Icons.app_registration_outlined),
                        title: Text(
                          translation(context: context, 'Registration Mode'),
                        ),
                        value: false,
                        onChanged: null,
                      ),
                      error: (e, st) => ListTile(
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: const Text('Error loading registration mode'),
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
                            const SizedBox(width: 6),
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
                    ),
                  ]);
                },
              ),
            ),

            // SECTION 2: Profile & Workspace
            buildSectionCard([
              ListTile(
                leading: Icon(Icons.account_circle_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Account')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AccountPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.group_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Users')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UsersPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.language_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Language')),
                trailing: LanguageDropdown(
                  borderColor: primaryColor.withOpacity(0.5),
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.extension_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Tools')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ToolsPage()),
                  );
                },
              ),
            ]),

            // SECTION 3: System & Info
            buildSectionCard([
              ListTile(
                leading: Icon(Icons.settings_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Settings')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.info_outline, color: primaryColor),
                title: Text(translation(context: context, 'About')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.feedback_outlined, color: primaryColor),
                title: Text(translation(context: context, 'Feedback')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const FeedbackPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.help_outline, color: primaryColor),
                title: Row(
                  children: [
                    Text(translation(context: context, 'Help')),
                    const SizedBox(width: 6),
                    CustomContainerChip(
                      label: translation(context: context, 'Under Construction'),
                    ),
                  ],
                ),
                onTap: () {},
              ),
            ]),

            // SECTION 4: Debug / UI Test Page
            if (kDebugMode)
              buildSectionCard([
                ListTile(
                  leading: Icon(Icons.bug_report_outlined, color: primaryColor),
                  title: Text(translation(context: context, 'UI Test Page')),
                  subtitle: Text(translation(context: context, 'Debug only')),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UiTestPage()),
                    );
                  },
                ),
              ]),
          ],
        ),
      ),
    );
  }
}