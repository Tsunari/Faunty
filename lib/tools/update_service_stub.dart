// Fallback (non-web) implementation to avoid importing dart:js_interop on mobile/desktop.
import 'package:flutter/material.dart';

class UpdateService {
  static Future<void> init({BuildContext? initialContext, BuildContext? Function()? contextProvider}) async {}
  static void dispose() {}
  static Future<void> manualCheck({ bool forceDialog = false, bool showUpToDateSnack = false, bool promptRefreshIfUpToDate = false }) async {}
}
