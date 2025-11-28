import 'package:faunty/components/role_gate.dart';
import 'package:faunty/firebase_options.dart';
import 'package:faunty/notifications/fcm/foreground_notification_wrapper.dart';
import 'package:faunty/notifications/notification_manager.dart';
import 'package:faunty/notifications/one_signal/onesignal_provider.dart';
import 'package:faunty/notifications/reminder_manager.dart';
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
import 'tools/update_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale(); // Localization setup
  // String storedLocale = loadFromStorage(); // with shared preferences or any other method
  // LocaleSettings.setLocaleRaw(storedLocale);
  await LanguageNotifier().loadLanguage();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  runApp(
    TranslationProvider(
      child: ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            // Initialize ReminderManager to listen for changes
            // We do this inside a Consumer to get access to ref
            // But we need to ensure it's only called once or handles re-calls gracefully.
            // Actually, putting it in the build method of a widget is better or using a provider observer.
            // Let's use a simple widget wrapper or init it in the root widget.
            return Faunty();
          },
        ),
      ),
    ),
  );
}

class Faunty extends ConsumerStatefulWidget {
  const Faunty({super.key});

  @override
  ConsumerState<Faunty> createState() => _FauntyState();
}

class _FauntyState extends ConsumerState<Faunty> {
  @override
  void initState() {
    super.initState();
    // Initialize services after the first frame to ensure context is available if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the Notification Manager with OneSignal provider
      final notificationManager = NotificationManager();
      notificationManager.setProvider(OneSignalNotificationProvider());
      notificationManager.init();

      if (kIsWeb) {
        UpdateService.init(
          contextProvider: () => rootNavigatorKey.currentContext,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Monitor for reminders
    ReminderManager().monitor(ref);

    final presetIndex = ref.watch(themePresetProvider);
    final preset = themePresets[presetIndex];
    // TODO: FIX ISSUE WITH STATUS BAR COLOR
    final isMonochrome = preset.name == 'Monochrome';
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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
      minRole: UserRole.spectator,
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
              (userAsync.value!.role == UserRole.user || userAsync.value!.role == UserRole.unknown)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.settings.name != '/user-welcome') {
                Navigator.of(context).pushNamedAndRemoveUntil('/user-welcome', (route) => false);
              }
            });
          }
          if (userAsync is AsyncData && userAsync.value != null && userAsync.value!.role == UserRole.archived) {
            // TODO: Show archived user page
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Your account is archived.'),
                ),
              ),
            );
          }
          // TODO: Same for other roles in the future (like spectator/ihvan-only view etc)
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
