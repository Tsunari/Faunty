import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  String? title,
  required Widget content,
  String cancelText = 'Cancel',
  String confirmText = 'Delete',
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title != null ? Text(title) : null,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? Colors.redAccent,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.bold,
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
  return showConfirmDialog(
    context: context,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Text(
          thingToDelete != null ? 'Delete $thingToDelete?' : 'Are you sure?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'This action cannot be undone.',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
