import 'package:flutter/foundation.dart';
// Colors: 🟢 🔴 🟡
// More Colors: Blue: 🔵, Orange: 🟠, Purple: 🟣, Brown: 🟤, Black: ⚫, White: ⚪

// WARNING
void printWarning(String message) {
  if (kDebugMode) print('🟡 $message');
}
// INFO
void printInfo(String message) {
  if (kDebugMode) print('🟢 $message');
}
// ERROR
void printError(String message) {
  if (kDebugMode) print('🔴 $message');
}