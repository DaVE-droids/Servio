import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Accessible status chip that pairs color with a label and optional icon.
class AppStatusChip extends StatelessWidget {
  /// Creates a status chip.
  const AppStatusChip({
    required this.label,
    required this.type,
    this.icon,
    super.key,
  });

  /// Status label.
  final String label;

  /// Semantic status type.
  final AppStatusChipType type;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AppStatusChipType.success => AppColors.success,
      AppStatusChipType.warning => AppColors.warning,
      AppStatusChipType.error => AppColors.error,
      AppStatusChipType.info => AppColors.information,
      AppStatusChipType.neutral => AppColors.secondary,
    };

    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

/// Semantic status colors supported by status chips.
enum AppStatusChipType {
  /// Successful or approved status.
  success,

  /// Pending or warning status.
  warning,

  /// Rejected or error status.
  error,

  /// Active or informational status.
  info,

  /// Draft or neutral status.
  neutral,
}
