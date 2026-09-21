import 'package:flutter/material.dart';

enum UnsavedChangesAction {
  save,
  discard,
  cancel,
}

/// Dialog prompting the user when opening a new document while the current document
/// has unsaved edits.
class UnsavedChangesDialog extends StatelessWidget {
  final String currentDocumentName;
  final String? newDocumentName;

  const UnsavedChangesDialog({
    super.key,
    required this.currentDocumentName,
    this.newDocumentName,
  });

  /// Shows the dialog and returns the chosen [UnsavedChangesAction].
  static Future<UnsavedChangesAction?> show(
    BuildContext context, {
    required String currentDocumentName,
    String? newDocumentName,
  }) {
    return showDialog<UnsavedChangesAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnsavedChangesDialog(
        currentDocumentName: currentDocumentName,
        newDocumentName: newDocumentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetText =
        newDocumentName != null ? ' before opening "$newDocumentName"' : '';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Unsaved Changes'),
        ],
      ),
      content: Text(
        'You have unsaved changes in "$currentDocumentName". '
        'Do you want to save your changes$targetText?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.discard),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
          child: const Text('Discard Changes'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.save),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
