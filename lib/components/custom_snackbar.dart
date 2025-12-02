import 'package:flutter/material.dart';

/// Shows a custom snackbar with consistent styling.
void showCustomSnackBar(BuildContext context, String message, {Color? backgroundColor, Duration? duration}) {
  final messenger = ScaffoldMessenger.of(context);
  // Only allow one snackbar at a time
  if (messenger.mounted) {
    // Flutter does not support a queue count, so we clear all before showing a new one
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
