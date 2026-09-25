import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tone.dart';

/// Confirmation dialog for decisions that matter. Returns `true` from
/// [showDialog] when confirmed.
class AppDialog extends StatelessWidget {
  /// Creates an app dialog.
  const AppDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.isDestructive = false,
    this.icon,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Dialog message.
  final String message;

  /// Confirm button label.
  final String confirmLabel;

  /// Cancel button label.
  final String cancelLabel;

  /// Confirm callback; defaults to closing with `true`.
  final VoidCallback? onConfirm;

  /// Styles the confirm button as destructive.
  final bool isDestructive;

  /// Optional icon above the title.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tone = isDestructive ? AppTone.error : AppTone.ink;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: icon == null
          ? null
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: tone.foreground),
            ),
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
              : null,
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
