// Dart script to extract all t("...") usages and update translation JSON
import 'dart:io';
import 'dart:convert';

import 'package:faunty/core/utils/key_normalizer.dart';

// Note: Avoid importing Flutter-dependent helpers here so this script can run with plain `dart`.
// import 'package:path/path.dart' as p; // Not needed

// Change these paths as needed
const dartSourceDir = 'lib';
const translationJsonPath = 'lib/i18n/en.i18n.json';


void main() async {
  final translationFile = File(translationJsonPath);
  Map<String, dynamic> translations = {};
  if (await translationFile.exists()) {
    translations = json.decode(await translationFile.readAsString());
  }

  final dartFiles = Directory(dartSourceDir)
      .listSync(recursive: true)
      .where((f) => f.path.endsWith('.dart'));

  // Match anything inside translation(context, '...') or translation(context, "...")
  final tSingleRegex = RegExp(r"translation\(\s*context\s*,\s*'([^']*)'(?:\s*,[^)]*)?\)");
  final tDoubleRegex = RegExp(r'translation\(\s*context\s*,\s*"([^"]*)"(?:\s*,[^)]*)?\)');
  final found = <String>{};

  for (final file in dartFiles) {
    final content = await File(file.path).readAsString();
    for (final match in tDoubleRegex.allMatches(content)) {
      final str = match.group(1);
      if (str != null && str.isNotEmpty) {
        // Only extract the string, not code
        found.add(str);
      }
    }
    for (final match in tSingleRegex.allMatches(content)) {
      final str = match.group(1);
      if (str != null && str.isNotEmpty) {
        found.add(str);
      }
    }
  }

  // Check for missing translations (value not found in any value of JSON)
  final missing = <String, String>{};
  for (final value in found) {
    // Replace all non-alphanumeric characters with underscores for valid Slang keys
    // Replace only Dart interpolations (${...}) in the extracted string with {placeholder}
    final valueWithPlaceholder = value.replaceAll(RegExp(r'\$\{[^}]+\}'), '{placeholder}');
    final key = normalizeKey(valueWithPlaceholder);
    if (!translations.containsKey(key) && !translations.values.contains(valueWithPlaceholder)) {
      missing[key] = valueWithPlaceholder;
    }
  }

  if (missing.isEmpty) {
    print('No missing translations found.');
    return;
  }

  // Pretty print missing translations
  print('\nMissing translations:');
  print('----------------------------------------------');
  print('| Key                                  | Value');
  print('----------------------------------------------');
  for (final entry in missing.entries) {
    final key = entry.key.padRight(36);
    final value = entry.value;
    print('| $key | $value');
  }

  print('\nTotal missing translations: ${missing.length}');

  stdout.write('\nAdd these to $translationJsonPath? (Y/n): ');
  final response = stdin.readLineSync();
  if (response != null && response.toLowerCase() == 'n') {
    print('Aborted. No changes made.');
    return;
  }

  // Add missing translations
  translations.addAll(missing);
  await translationFile.writeAsString(JsonEncoder.withIndent('  ').convert(translations));
  print('Done. ${missing.length} new keys added to $translationJsonPath');
}