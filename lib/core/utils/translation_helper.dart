import 'package:faunty/core/utils/key_normalizer.dart';
import 'package:flutter/widgets.dart';
import 'package:faunty/core/i18n/strings.g.dart';

/// Translates a string based on the current locale settings.
///
/// This function retrieves the localized version of the provided string
/// according to the active locale. Note that passing arguments for dynamic
/// string interpolation is currently not supported. And I think it will not be supported in the future.
///
/// Returns the translated string for the current locale.
String translation(String value, {BuildContext? context, Map<String, Object>? args}) {
  final key = normalizeKey(value);
  final f = context != null ? Translations.of(context) : t;
  final result = args != null ? f[key](args) : f[key]; // args not supported yet
  return result ?? value;
}