import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A colour role a component can take on: a module (attendance, logbook,
/// supervision) or an outcome (success, warning, error).
///
/// Components ask for a tone rather than a raw colour, so the module
/// colour-coding stays consistent everywhere.
enum AppTone {
  /// Placement decisions and supervision.
  ink(AppColors.ink, AppColors.inkSoft, AppColors.ink),

  /// Attendance.
  sky(AppColors.skyStrong, AppColors.skySoft, AppColors.sky),

  /// Logbook.
  blush(AppColors.blushStrong, AppColors.blushSoft, AppColors.blush),

  /// Approved, completed, on track.
  success(AppColors.success, AppColors.successSoft, AppColors.successSoft),

  /// Waiting on someone, or needs attention.
  warning(AppColors.warning, AppColors.warningSoft, AppColors.warningSoft),

  /// Rejected, failed, or missed.
  error(AppColors.error, AppColors.errorSoft, AppColors.errorSoft),

  /// Nothing to report.
  neutral(AppColors.textSecondary, AppColors.mist, AppColors.line);

  const AppTone(this.foreground, this.background, this.fill);

  /// Text and icon colour, readable on [background].
  final Color foreground;

  /// Pale background for chips, badges, and tinted surfaces.
  final Color background;

  /// Stronger fill for highlighted tiles and calendar stamps.
  final Color fill;
}
