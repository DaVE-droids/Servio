import 'package:flutter/material.dart';

/// Standard Servio text field with consistent styling and validation display.
class AppTextField extends StatelessWidget {
  /// Creates an app text field.
  const AppTextField({
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  /// Field label.
  final String label;

  /// Optional text controller.
  final TextEditingController? controller;

  /// Optional placeholder text.
  final String? hintText;

  /// Optional validation message.
  final String? errorText;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Whether the field obscures input.
  final bool obscureText;

  /// Maximum line count.
  final int maxLines;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}
