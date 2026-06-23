import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:faunty/features/notifications/data/fcm/notification_service.dart';
import 'package:faunty/features/notifications/data/fcm/token_management.dart';

Future<PackageInfo> getAppInfo() async {
  return await PackageInfo.fromPlatform();
}

Color notFoundIconColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withAlpha(180);
}

Future<void> logout({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  // Try to dissociate the current device token from the user without
  // prompting the browser for permissions. If a token exists it will
  // remove the `uid` field; the token document itself is preserved.
  // try {
  //   final token = await NotificationService.fetchTokenIfAllowed();
  //   if (token != null) {
  //     await TokenManager.clearUidForToken(token);
  //   }
  // } catch (e) {
  //   // ignore - best-effort cleanup
  // }

  await FirebaseAuth.instance.signOut();
  ref.invalidate(userProvider);
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

/// Monochrome ThemeData for pure black, white, and greyscale UI
final ThemeData monochromeThemeDataDark = ThemeData(
  brightness: Brightness.dark,
  // Use pure black where possible for maximum contrast and OLED friendliness
  colorScheme: ColorScheme.dark().copyWith(
    primary: Colors.white,
    onPrimary: Colors.black,
  // Prefer white/black only; use white for accent on dark background and black for text on that accent
  secondary: Colors.white,
  onSecondary: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
    error: Colors.red,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.black,
  // Make cards and surfaces fully black to minimize non-black areas
  cardColor: Colors.black,
  // Subtle divider that's visible on black
  dividerColor: Colors.white12,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black, // AMOLED pure black
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    elevation: 0,
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: const TextTheme(
  bodyLarge: TextStyle(color: Colors.white),
  bodyMedium: TextStyle(color: Colors.white),
  bodySmall: TextStyle(color: Colors.white),
  titleLarge: TextStyle(color: Colors.white),
  titleMedium: TextStyle(color: Colors.white),
  titleSmall: TextStyle(color: Colors.white),
  labelLarge: TextStyle(color: Colors.white),
  labelMedium: TextStyle(color: Colors.white),
  labelSmall: TextStyle(color: Colors.white),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
  // prefer pure black fill for input containers in dark mode
  fillColor: Colors.black,
    border: OutlineInputBorder(),
    hintStyle: TextStyle(color: Colors.white54),
    labelStyle: TextStyle(color: Colors.white),
  ),
  snackBarTheme: const SnackBarThemeData(
  // use black background for snackbars in dark mode to remain pitch-black
  backgroundColor: Colors.black,
  contentTextStyle: TextStyle(color: Colors.white),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.black,
    textStyle: const TextStyle(color: Colors.white),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.black,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.black,
  ),
  // eliminate colored highlights; keep interactions subtle on black
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Colors.white),
    checkColor: WidgetStateProperty.all(Colors.black),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.all(Colors.white),
  ),
  switchTheme: SwitchThemeData(
    // White/thumb-on for high contrast on black; slightly dim when off.
    // Use a simple all/selected rule to avoid state mismatches.
    // Thumb should be black when the switch is ON, white-ish when OFF.
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.black;
      return Colors.white70;
    }),
    // Track should be white when ON to create a white background, transparent when OFF.
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return Colors.transparent;
    }),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
  // Floating action buttons: keep them compact and high-contrast for AMOLED
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Colors.white,
  ),
  // Bottom navigation: fully black background, stronger contrast for selected icons
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Colors.black,
  unselectedItemColor: Colors.white38,
    elevation: 0,
    showUnselectedLabels: false,
  ),
  // Navigation bar (Material 3) explicit theme to avoid default blue selection
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.black,
  // Keep labels and icons white at all times for strict monochrome; use a subtle indicator so white text stays visible
  indicatorColor: Colors.white12,
  labelTextStyle: MaterialStatePropertyAll(const TextStyle(color: Colors.white)),
  iconTheme: MaterialStatePropertyAll(const IconThemeData(color: Colors.white)),
  ),
);

/// Monochrome ThemeData for pure white, black, and greyscale UI (light mode)
final ThemeData monochromeThemeDataLight = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light().copyWith(
    primary: Colors.black,
    onPrimary: Colors.white,
    // Use black as the secondary accent in light mode and white for text on that accent
    secondary: Colors.black,
    onSecondary: Colors.white,
    // 'background'/'onBackground' deprecated — use surface/onSurface instead
    surface: Colors.white,
    onSurface: Colors.black,
    error: Colors.red,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  // subtle divider using translucent black to remain monochrome
  dividerColor: Colors.black12,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
  textTheme: const TextTheme(
  bodyLarge: TextStyle(color: Colors.black),
  bodyMedium: TextStyle(color: Colors.black),
  bodySmall: TextStyle(color: Colors.black),
  titleLarge: TextStyle(color: Colors.black),
  titleMedium: TextStyle(color: Colors.black),
  titleSmall: TextStyle(color: Colors.black),
  labelLarge: TextStyle(color: Colors.black),
  labelMedium: TextStyle(color: Colors.black),
  labelSmall: TextStyle(color: Colors.black),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
  fillColor: Colors.white,
    border: OutlineInputBorder(),
    hintStyle: TextStyle(color: Colors.black54),
    labelStyle: TextStyle(color: Colors.black),
  ),
  snackBarTheme: const SnackBarThemeData(
  // light-mode snackbars use white background with black text (inverse of dark)
  backgroundColor: Colors.white,
  contentTextStyle: TextStyle(color: Colors.black),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    textStyle: TextStyle(color: Colors.black),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.white,
  ),
  // subtle monochrome interaction ripple/highlight
  highlightColor: Colors.black12,
  splashColor: Colors.black12,
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Colors.black),
    checkColor: WidgetStateProperty.all(Colors.white),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.all(Colors.black),
  ),
  switchTheme: SwitchThemeData(
    // Inverted from dark: thumb should be white when ON, darker when OFF
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return Colors.black87;
    }),
    // Track: black when ON to create a dark background behind the white thumb
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.black;
      return Colors.transparent;
    }),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Colors.black,
  ),
  // Floating action buttons for light mode: inverted from dark (black background, white icon)
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  // Bottom navigation for light mode: white background, black selected icons/text
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black38,
    elevation: 0,
    showUnselectedLabels: false,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Colors.black12,
    labelTextStyle: MaterialStatePropertyAll(TextStyle(color: Colors.black)),
    iconTheme: MaterialStatePropertyAll(IconThemeData(color: Colors.black)),
  ),
);