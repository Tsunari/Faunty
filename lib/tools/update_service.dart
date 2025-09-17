import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:js_interop';
import '../components/custom_snackbar.dart';
import '../tools/translation_helper.dart';

class UpdateService {
  static const _repo = 'Tsunari/Faunty-React';
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static bool _checkedOnce = false;

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

  static Future<void> checkForUpdateAndPrompt(BuildContext context) async {
    if (_checkedOnce) return; // avoid multiple popups
    _checkedOnce = true;
    if (!kIsWeb) return;

    final current = await _getCurrentVersion();
    final latestTag = await _getLatestReleaseTag();
    if (current == null || latestTag == null) return;

    if (_compareVersions(latestTag, current) > 0) {
      if (!context.mounted) return;
      final shouldReload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(translation(context: context, 'Update available')),
          content: Text(translation(context: context, 'A new version (%s) is available. Refresh to update?').replaceFirst('%s', latestTag)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(translation(context: context, 'Later')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(translation(context: context, 'Refresh now')),
            ),
          ],
        ),
      );

      if (shouldReload == true) {
        if (!context.mounted) return;
        showCustomSnackBar(context, translation(context: context, 'Refreshing to update...'));
        _reloadPage();
      }
    }
  }
}

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
