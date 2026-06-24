import 'package:faunty/features/auth/presentation/widgets/role_gate.dart';
import 'package:faunty/firebase_options.dart';
import 'package:faunty/features/notifications/data/notification_manager.dart';
import 'package:faunty/features/notifications/data/one_signal/onesignal_provider.dart';
import 'package:faunty/features/notifications/data/reminder_manager.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:faunty/features/communication/presentation/pages/communication_page.dart';
import 'package:faunty/features/lists/presentation/pages/lists_page.dart';
import 'package:faunty/features/tracking/presentation/pages/tracking_page.dart';
import 'package:faunty/core/i18n/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'globals.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/profile/presentation/pages/home_page.dart';
import 'package:faunty/features/auth/presentation/pages/login_page.dart';
import 'package:faunty/features/profile/presentation/pages/more_page.dart';
import 'package:faunty/features/profile/presentation/widgets/navigation_bar.dart';
import 'package:faunty/features/auth/presentation/pages/splash_page.dart';
import 'package:faunty/features/auth/presentation/pages/user_welcome_page.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/core/i18n/strings.g.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/theme/theme_provider.dart';
import 'package:faunty/features/profile/presentation/widgets/theme_cards_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:faunty/core/utils/update_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:faunty/core/utils/pwa_install.dart';

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
              dialogTheme: DialogThemeData(
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
      darkTheme: isMonochrome
          ? monochromeThemeDataDark
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: preset.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              dialogTheme: DialogThemeData(
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
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
        extendBody: true,
        body: Stack(
          children: [
            _pages[_selectedIndex],
            const PwaInstallBanner(),
          ],
        ),
        bottomNavigationBar: NavBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}