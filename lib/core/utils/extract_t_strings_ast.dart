import 'dart:io';
import 'dart:convert';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:faunty/core/utils/key_normalizer.dart';

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

  final found = <String>{};

  for (final file in dartFiles) {
    final content = File(file.path).readAsStringSync();
    final result = parseString(content: content, throwIfDiagnostics: false);
    final unit = result.unit;
  // Use accept() to traverse the entire tree and let the visitor recurse properly
  unit.accept(_TranslationVisitor(found));
  }

  // Check for missing translations (value not found in any value of JSON)
  final missing = <String, String>{};
  for (final value in found) {
    // Replace Dart interpolations (${...}) in the extracted string with {placeholder}
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

class _TranslationVisitor extends GeneralizingAstVisitor<void> {
  final Set<String> found;
  _TranslationVisitor(this.found);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Handles calls like: translation(context, '...') and target.translation(...)
    if (node.methodName.name == 'translation' && node.argumentList.arguments.length >= 2) {
  final arg = node.argumentList.arguments[1];
  final val = _extractText(arg);
  if (val != null && val.isNotEmpty) found.add(val);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Handles top-level function calls represented as FunctionExpressionInvocation
    // e.g., translation(context, '...') when resolved as a function identifier
    final fn = node.function;
    String? name;
    if (fn is SimpleIdentifier) name = fn.name;
    if (fn is PrefixedIdentifier) name = fn.identifier.name;

    if (name == 'translation' && node.argumentList.arguments.length >= 2) {
      final arg = node.argumentList.arguments[1];
      final val = _extractText(arg);
      if (val != null && val.isNotEmpty) found.add(val);
    }
    super.visitFunctionExpressionInvocation(node);
  }

  String? _extractText(Expression arg) {
    if (arg is SimpleStringLiteral) {
      return arg.value;
    }
    if (arg is AdjacentStrings) {
      final buffer = StringBuffer();
      for (final s in arg.strings) {
        final part = _extractText(s);
        if (part != null) buffer.write(part);
      }
      return buffer.toString();
    }
    if (arg is StringInterpolation) {
      final buffer = StringBuffer();
      for (final e in arg.elements) {
        if (e is InterpolationString) {
          buffer.write(e.value);
        } else {
          buffer.write('{placeholder}');
        }
      }
      return buffer.toString();
    }
    if (arg is StringLiteral) {
      // Fallback: try stringValue when available
      return arg.stringValue;
    }
    return null;
  }
}