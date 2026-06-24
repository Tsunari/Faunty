import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  String? title,
  required Widget content,
  String cancelText = 'Cancel',
  String confirmText = 'Confirm',
  Color? confirmColor,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title != null
          ? Center(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: content,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      actions: [
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              cancelText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? theme.colorScheme.primary,
              foregroundColor: confirmColor != null 
                  ? Colors.white 
                  : theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool?> showDeleteDialog({
  required BuildContext context,
  String? thingToDelete,
}) {
  final theme = Theme.of(context);
  return showConfirmDialog(
    context: context,
    confirmText: 'Delete',
    confirmColor: theme.colorScheme.error,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded, 
            color: theme.colorScheme.error, 
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          thingToDelete != null ? 'Delete $thingToDelete?' : 'Are you sure?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
