import 'package:flutter/material.dart';

/// Standard Servio text field with consistent styling and validation display.
///
/// Password fields ([obscureText]) get a show/hide toggle automatically.
class AppTextField extends StatefulWidget {
  /// Creates an app text field.
  const AppTextField({
    required this.label,
    this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.prefixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.maxLength,
    super.key,
  });

  /// Field label.
  final String label;

  /// Optional text controller.
  final TextEditingController? controller;

  /// Optional placeholder text.
  final String? hintText;

  /// Optional guidance under the field.
  final String? helperText;

  /// Optional validation message.
  final String? errorText;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Whether the field obscures input.
  final bool obscureText;

  /// Maximum line count.
  final int maxLines;

  /// Minimum line count for multi-line fields.
  final int? minLines;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Auto-capitalization behavior. Defaults to none so fields like email
  /// aren't capitalized by the platform's autocapitalization heuristics.
  final TextCapitalization textCapitalization;

  /// Whether the platform should offer autocorrect suggestions.
  final bool autocorrect;

  /// Optional leading icon.
  final IconData? prefixIcon;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Lets password managers and the browser fill the field.
  final Iterable<String>? autofillHints;

  /// Optional character limit, shown as a counter.
  final int? maxLength;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.obscureText ? false : widget.autocorrect,
      enableSuggestions: !widget.obscureText,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 2,
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 20),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
