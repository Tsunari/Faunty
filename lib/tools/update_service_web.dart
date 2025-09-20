import 'dart:async';
import 'dart:convert';
// Web-specific implementation using package:web for DOM access.
// Avoids direct low-level js_interop in favor of typed APIs.
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../components/custom_snackbar.dart';
import '../tools/translation_helper.dart';

class UpdateService {
  static const _repo = 'Tsunari/Faunty';
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static const Duration periodicInterval = Duration(hours: 3);
  static const Duration visibilityMinGap = Duration(minutes: 15);
  static bool _dialogShownForCurrentVersion = false;
  static DateTime? _lastSuccessfulCheck;
  static Timer? _periodicTimer;
  static Timer? _visibilityPollTimer;
  static bool _initialized = false;
  static String? _cachedCurrentVersion;
  static BuildContext? Function()? _contextProvider;

  static Future<String?> _getCurrentVersion() async {
    try { final info = await PackageInfo.fromPlatform(); return info.version; } catch (_) { return null; }
  }

  static Future<String?> _getLatestReleaseTag() async {
    try {
      final res = await http.get(Uri.parse(_releasesUrl), headers: {'Accept': 'application/vnd.github+json'});
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json = jsonDecode(res.body);
      return (json['tag_name'] as String?)?.trim();
    } catch (_) { return null; }
  }

  static int _compareVersions(String a, String b) {
    String norm(String s) => s.startsWith('v') ? s.substring(1) : s;
    final pa = norm(a).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = norm(b).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = (i < pa.length ? pa[i] : 0);
      final vb = (i < pb.length ? pb[i] : 0);
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  static Future<void> init({BuildContext? initialContext, BuildContext? Function()? contextProvider}) async {
    if (!kIsWeb) return;
    if (_initialized) return;
    _initialized = true;
    _contextProvider = contextProvider ?? () => initialContext;
    unawaited(_performCheck(showDialogIfNewer: true));
    _periodicTimer = Timer.periodic(periodicInterval, (_) { _performCheck(showDialogIfNewer: true); });
    _startVisibilityPolling();
  }

  static void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _visibilityPollTimer?.cancel();
    _visibilityPollTimer = null;
  }

  static Future<void> manualCheck({ bool forceDialog = false, bool showUpToDateSnack = false, bool promptRefreshIfUpToDate = false, }) async { 
    final bool foundNewer = await _performCheck(showDialogIfNewer: true, forceDialog: forceDialog); 
    if (!foundNewer) { final ctx = _obtainContext(); 
    if (ctx != null && ctx.mounted) { 
      if (showUpToDateSnack) { showCustomSnackBar(ctx, translation(context: ctx, 'You are up to date.')); } 
      if (promptRefreshIfUpToDate) { 
        unawaited(
          showDialog<bool>( 
            context: ctx, 
            builder: (dCtx) => AlertDialog( 
              title: Text(translation(context: dCtx, 'Reload page?')), 
              content: Text(translation(context: dCtx, 'No new version found. Do you still want to refresh?')), 
              actions: [ 
                TextButton(
                  onPressed: () => Navigator.of(dCtx).pop(false), 
                  child: Text(translation(context: dCtx, 'Cancel'))
                ), 
                ElevatedButton(
                  onPressed: () => Navigator.of(dCtx).pop(true), 
                  child: Text(translation(context: dCtx, 'Refresh'))
                ), 
              ], 
            ), 
          ).then((accepted) { 
            if (accepted == true && ctx.mounted) { showCustomSnackBar(ctx, translation(context: ctx, 'Refreshing...'));
            _reloadPage(); } })
        ); 
      } 
    } } 
  }

  static Future<bool> _performCheck({required bool showDialogIfNewer, bool forceDialog = false}) async { 
    if (kDebugMode) return false;
    try { 
      final now = DateTime.now(); 
      final current = _cachedCurrentVersion ??= await _getCurrentVersion(); 
      if (current == null) return false; 
      final latestTag = await _getLatestReleaseTag(); 
      if (latestTag == null) return false; 
      _lastSuccessfulCheck = now; 
      final newer = _compareVersions(latestTag, current) > 0; 
      if (!newer) return false;
      if (!_shouldShowDialogFor(latestTag) && !forceDialog) return false;
      final ctx = _obtainContext();
      if (ctx == null || !ctx.mounted) return false;
      final accepted = await showDialog<bool>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(translation(context: dialogCtx, 'Update available')),
          content: Text(translation(context: dialogCtx, 'A new version (%s) is available. Refresh to update?').replaceFirst('%s', latestTag)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: Text(translation(context: dialogCtx, 'Later'))),
            ElevatedButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: Text(translation(context: dialogCtx, 'Refresh now'))),
          ],
        ),
      );
      if (accepted == true && ctx.mounted) {
        showCustomSnackBar(ctx, translation(context: ctx, 'Refreshing to update...'));
        _dialogShownForCurrentVersion = true;
        _reloadPage();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _shouldShowDialogFor(String latestTag) { if (_cachedCurrentVersion == null) return false; if (_dialogShownForCurrentVersion) return false; return true; }
  static BuildContext? _obtainContext() { try { if (_contextProvider != null) return _contextProvider!(); } catch (_) {} return null; }
  static void _startVisibilityPolling() {
    // Poll every 2 minutes; lightweight and avoids event listener typing issues.
    _visibilityPollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!kIsWeb) return;
      final hidden = web.document.hidden;
      if (!hidden) {
        final last = _lastSuccessfulCheck;
        if (last == null || DateTime.now().difference(last) > visibilityMinGap) {
          _performCheck(showDialogIfNewer: true);
        }
      }
    });
  }
}
void _reloadPage() {
  if (!kIsWeb) return;
  () async {
    try {
      // 1) Unregister all service workers (avoid old SW caching)
      final sw = web.window.navigator.serviceWorker;
      try {
        final regs = await sw.getRegistrations().toDart; // JSArray<ServiceWorkerRegistration>
        for (final reg in regs.toDart) {
          try { await reg.unregister().toDart; } catch (_) {}
        }
      } catch (_) {}

      // 2) Clear CacheStorage (remove previously cached assets)
      try {
        final cacheStorage = web.window.caches;
        final keysArr = await cacheStorage.keys().toDart; // JSArray<JSString>
        for (final jsStr in keysArr.toDart) {
          final key = jsStr.toDart;
          try { await cacheStorage.delete(key).toDart; } catch (_) {}
        }
      } catch (_) {}

      // 3) Force a navigation with a cache-busting query param
      final href = web.window.location.href;
      final uri = Uri.parse(href);
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final qp = Map<String, String>.from(uri.queryParameters)..['cache-bust'] = ts;
      final busted = uri.replace(queryParameters: qp).toString();
      web.window.location.replace(busted);
    } catch (_) {
      // Fallback to normal reload
      try { web.window.location.reload(); } catch (_) {}
    }
  }();
}
