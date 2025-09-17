// Conditional export selecting web (JS interop) implementation when available.
// For non-web targets (Android/iOS/desktop), stub is used avoiding dart:js_interop import.
export 'update_service_stub.dart'
if (dart.library.js_interop) 'update_service_web.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
  static bool _initialized = false;
  static String? _cachedCurrentVersion;

  // Root context accessor provided by caller (e.g., main) to show dialogs.
  static BuildContext? Function()? _contextProvider;

  static Future<String?> _getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getLatestReleaseTag() async {
    try {
      final res = await http.get(Uri.parse(_releasesUrl), headers: {
        'Accept': 'application/vnd.github+json',
      });
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json = jsonDecode(res.body);
      final tag = (json['tag_name'] as String?)?.trim();
      return tag;
    } catch (_) {
      return null;
    }
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

    // Initial check (non-blocking)
    unawaited(_performCheck(showDialogIfNewer: true));

    // Periodic timer
    _periodicTimer = Timer.periodic(periodicInterval, (_) {
      _performCheck(showDialogIfNewer: true);
    });

    // Visibility listener (web only) via JS interop
    _installVisibilityListener();
  }

  static void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  static Future<void> manualCheck({
    bool forceDialog = false,
    bool showUpToDateSnack = false,
    bool promptRefreshIfUpToDate = false,
  }) async {
    final bool foundNewer = await _performCheck(showDialogIfNewer: true, forceDialog: forceDialog);
    if (!foundNewer) {
      final ctx = _obtainContext();
      if (ctx != null && ctx.mounted) {
        if (showUpToDateSnack) {
          showCustomSnackBar(ctx, translation(context: ctx, 'You are up to date.'));
        }
        if (promptRefreshIfUpToDate) {
          // Offer a manual refresh anyway
          unawaited(showDialog<bool>(
            context: ctx,
            builder: (dCtx) => AlertDialog(
              title: Text(translation(context: dCtx, 'Reload page?')),
              content: Text(translation(context: dCtx, 'No new version found. Do you still want to refresh?')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dCtx).pop(false),
                  child: Text(translation(context: dCtx, 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dCtx).pop(true),
                  child: Text(translation(context: dCtx, 'Refresh')),
                ),
              ],
            ),
          ).then((accepted) {
            if (accepted == true && ctx.mounted) {
              showCustomSnackBar(ctx, translation(context: ctx, 'Refreshing...'));
              _reloadPage();
            }
          }));
        }
      }
    }
  }

  static Future<bool> _performCheck({required bool showDialogIfNewer, bool forceDialog = false}) async {
    try {
      final now = DateTime.now();
      final current = _cachedCurrentVersion ??= await _getCurrentVersion();
      if (current == null) return false;
      final latestTag = await _getLatestReleaseTag();
      if (latestTag == null) return false;
      _lastSuccessfulCheck = now;
      final newer = _compareVersions(latestTag, current) > 0;
      if (!newer) return false; // nothing to do
      if (!_shouldShowDialogFor(latestTag) && !forceDialog) return false;
      final ctx = _obtainContext();
      if (ctx == null || !ctx.mounted) return false;
      final accepted = await showDialog<bool>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(translation(context: dialogCtx, 'Update available')),
          content: Text(translation(context: dialogCtx, 'A new version (%s) is available. Refresh to update?').replaceFirst('%s', latestTag)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(translation(context: dialogCtx, 'Later')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(translation(context: dialogCtx, 'Refresh now')),
            ),
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
      // swallow errors silently
      return false;
    }
  }

  static bool _shouldShowDialogFor(String latestTag) {
    if (_cachedCurrentVersion == null) return false;
    if (_dialogShownForCurrentVersion) return false; // already shown this session
    return true;
  }

  static BuildContext? _obtainContext() {
    try {
      if (_contextProvider != null) return _contextProvider!();
    } catch (_) {}
    return null;
  }

  static void _installVisibilityListener() {
    if (!kIsWeb) return;
    // JS: document.addEventListener('visibilitychange', ...)
    _addVisibilityListener(_visibilityCallback.toJS);
  }

  static void _visibilityCallback() {
    final hidden = jsDocumentHidden;
    if (!hidden) {
      final last = _lastSuccessfulCheck;
      if (last == null || DateTime.now().difference(last) > visibilityMinGap) {
        _performCheck(showDialogIfNewer: true);
      }
    }
  }

  static void _addVisibilityListener(JSFunction cb) {
    try { jsDocumentAddEventListener('visibilitychange'.toJS, cb); } catch (_) {}
  }
}

// JS interop bindings moved to top-level (cannot annotate inside non-@JS class)
@JS('document.hidden')
external bool get jsDocumentHidden;

@JS('document.addEventListener')
external void jsDocumentAddEventListener(JSString event, JSFunction callback);

@JS('location')
external _JSLocation get _location;

@JS()
@staticInterop
class _JSLocation {}

extension _JSLocationExt on _JSLocation {
  external void reload();
}

void _reloadPage() {
  if (kIsWeb) {
    _location.reload();
  }
}
