import 'package:flutter/material.dart';

/// Semantic color tokens defined by the Servio Design System.
abstract final class AppColors {
  /// Primary actions, active navigation, links, and highlights.
  static const primary = Color(0xFF2563EB);

  /// Supporting actions and secondary emphasis.
  static const secondary = Color(0xFF64748B);

  /// Approved, completed, and successful states.
  static const success = Color(0xFF16A34A);

  /// Pending review, drafts, and missing-information states.
  static const warning = Color(0xFFF59E0B);

  /// Rejections, validation failures, and critical alerts.
  static const error = Color(0xFFDC2626);

  /// Informational notifications and guidance.
  static const information = Color(0xFF0EA5E9);

  /// Default application background.
  static const background = Color(0xFFF8FAFC);

  /// Default surface color for cards and sheets.
  static const surface = Color(0xFFFFFFFF);

  /// Divider and border color.
  static const divider = Color(0xFFE2E8F0);

  /// Primary body text color.
  static const textPrimary = Color(0xFF0F172A);

  /// Secondary body text color.
  static const textSecondary = Color(0xFF64748B);
}
