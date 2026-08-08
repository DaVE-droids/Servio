import 'package:flutter/material.dart';

/// Standard Servio button with primary, secondary, text, and destructive variants.
class AppButton extends StatelessWidget {
  /// Creates a standard button.
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    super.key,
  });

  /// Button label.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Visual hierarchy for the button.
  final AppButtonVariant variant;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final effectiveOnPressed = isLoading ? null : onPressed;

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: effectiveOnPressed,
        child: child,
      ),
    };
  }
}

/// Supported button variants from the Design System.
enum AppButtonVariant {
  /// Main action on a screen.
  primary,

  /// Supporting action.
  secondary,

  /// Low-priority action.
  text,

  /// Irreversible or critical action.
  destructive,
}
