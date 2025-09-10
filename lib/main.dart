import 'package:faunty/components/role_gate.dart';
import 'package:faunty/firebase_options.dart';
import 'package:faunty/notifications/notification_service.dart';
import 'package:faunty/notifications/foreground_notification_wrapper.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/pages/communication/communication_page.dart';
import 'package:faunty/pages/lists/lists_page.dart';
import 'package:faunty/pages/tracking/tracking_page.dart';
import 'package:faunty/state_management/language_provider.dart';
import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home/home_page.dart';
import 'pages/login.dart';
import 'pages/more/more_page.dart';
import 'components/navigation_bar.dart';
import 'pages/splash_page.dart';
import 'pages/welcome/user_welcome_page.dart';
import 'state_management/user_provider.dart';
import 'package:faunty/i18n/strings.g.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'state_management/theme_provider.dart';
import 'components/theme_cards_selector.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale(); // Localization setup
  // String storedLocale = loadFromStorage(); // with shared preferences or any other method
  // LocaleSettings.setLocaleRaw(storedLocale);
  await LanguageNotifier().loadLanguage();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Fire-and-forget init after first frame so app startup is not blocked.
  // Also avoid asking permission immediately — we'll ask later from UI.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.init(requestPermissions: false).catchError((e) {
      if (kDebugMode) print('NotificationService init error: $e');
    });
  });
  runApp(
    TranslationProvider(
      child: ProviderScope(
        child: Faunty(),
      ),
    ),
  );
}

class Faunty extends ConsumerWidget {
  const Faunty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetIndex = ref.watch(themePresetProvider);
    final preset = themePresets[presetIndex];
    final isMonochrome = preset.name == 'Monochrome';
    return MaterialApp(
      builder: (context, child) => ForegroundNotificationWrapper(child: child ?? const SizedBox.shrink()),
      title: translation(context: context, 'Faunty'),
      debugShowCheckedModeBanner: false,
      theme: isMonochrome
          ? monochromeThemeDataLight
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: preset.seedColor),
              useMaterial3: true,
            ),
      darkTheme: isMonochrome
          ? monochromeThemeDataDark
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: preset.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
      themeMode: ref.watch(themeProvider).value == AppThemeMode.dark
          ? ThemeMode.dark
          : ref.watch(themeProvider).value == AppThemeMode.light
          ? ThemeMode.light
          : ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainPage(),
        '/user-welcome': (context) => const UserWelcomePage(),
      },
    );
  }
}

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    CommunicationPage(),
    TrackingPage(),
    ListsPage(),
    MorePage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    return RoleGate(
      minRole: UserRole.talebe,
      showChildOnPages: ['/login'],
      fallback: Builder(
        builder: (context) {
          // check if user is logged in if not go to login page
          if (userAsync is AsyncData && userAsync.value == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.settings.name != '/login') {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            });
          }
          if (userAsync is AsyncData &&
              userAsync.value != null &&
              userAsync.value!.role == UserRole.user) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.settings.name != '/user-welcome') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const UserWelcomePage(),
                    settings: const RouteSettings(name: '/user-welcome'),
                  ),
                );
              }
            });
          }
          return const SizedBox.shrink();
        },
      ),
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}
