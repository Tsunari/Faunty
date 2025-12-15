import 'package:faunty/components/role_gate.dart';
import 'package:faunty/firebase_options.dart';
import 'package:faunty/notifications/notification_manager.dart';
import 'package:faunty/notifications/one_signal/onesignal_provider.dart';
import 'package:faunty/notifications/reminder_manager.dart';
import 'package:faunty/models/user_roles.dart';
import 'package:faunty/pages/communication/communication_page.dart';
import 'package:faunty/pages/lists/lists_page.dart';
import 'package:faunty/pages/tracking/tracking_page.dart';
import 'package:faunty/state_management/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:faunty/models/user_entity.dart';
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
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found or inaccessible, app will continue with defaults
    if (kDebugMode) {
      print('Warning: .env file not found or could not be loaded: $e');
    }
  }

  // Initialize the Notification Manager with OneSignal provider early
  final notificationManager = NotificationManager();
  notificationManager.setProvider(OneSignalNotificationProvider());
  await notificationManager.init();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (kIsWeb) {
      UpdateService.init(
        contextProvider: () => rootNavigatorKey.currentContext,
      );
    }
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
    // Monitor for reminders
    ReminderManager().monitor(ref);

    final presetIndex = ref.watch(themePresetProvider);
    final preset = themePresets[presetIndex];
    // TODO: FIX ISSUE WITH STATUS BAR COLOR
    final isMonochrome = preset.name == 'Monochrome';
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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
    // Handle navigation side-effects here using ref.listen
    ref.listen<AsyncValue<UserEntity?>>(userProvider, (previous, next) {
      final user = next.asData?.value;
      
      // 1. User logged out
      if (user == null) {
        // If we are already on login or splash, don't do anything.
        // But since this is MainPage, we are likely on /home.
        // We should navigate to login.
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      // 2. User restricted (role == user or unknown)
      if (user.role == UserRole.user || user.role == UserRole.unknown) {
        Navigator.of(context).pushNamedAndRemoveUntil('/user-welcome', (route) => false);
        return;
      }
    });

    final userAsync = ref.watch(userProvider);
    
    // Handle "Archived" state explicitly before RoleGate if we want a full screen blocking UI
    if (userAsync.asData?.value?.role == UserRole.archived) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Your account is archived.'),
          ),
        ),
      );
    }

    return RoleGate(
      minRole: UserRole.spectator,
      showChildOnPages: ['/login'],
      // Fallback is just an empty box now, because navigation is handled by ref.listen
      fallback: const SizedBox.shrink(),
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
