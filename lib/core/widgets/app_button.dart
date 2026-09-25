import 'package:flutter/material.dart';

/// Standard Servio button with primary, secondary, text, and destructive
/// variants.
///
/// While [isLoading] the label is replaced by a spinner and taps are
/// ignored, so a slow save can't be submitted twice.
class AppButton extends StatelessWidget {
  /// Creates a standard button.
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
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

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onFilled = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive => true,
      _ => false,
    };

    final Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isLoading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: onFilled ? Colors.white : colorScheme.primary,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
    );

    final effectiveOnPressed = isLoading ? null : onPressed;
    // Keep a filled look while loading, rather than greying out as if the
    // button were disabled.
    final loadingStyle = isLoading && onFilled
        ? FilledButton.styleFrom(
            disabledBackgroundColor: variant == AppButtonVariant.destructive
                ? colorScheme.error
                : colorScheme.primary,
          )
        : null;

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        style: loadingStyle,
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
          backgroundColor: colorScheme.error,
          disabledBackgroundColor: isLoading ? colorScheme.error : null,
        ),
        onPressed: effectiveOnPressed,
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
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
