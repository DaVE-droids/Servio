import 'package:flutter/material.dart';

import '../../app/theme/app_radii.dart';
import '../../app/theme/app_tone.dart';

/// A status pill: a coloured dot and a label on a pale background.
///
/// The dot and the words both carry the status, so it never relies on
/// colour alone.
class AppStatusChip extends StatelessWidget {
  /// Creates a status chip from a semantic [type].
  const AppStatusChip({
    required this.label,
    this.type = AppStatusChipType.neutral,
    this.tone,
    this.icon,
    super.key,
  });

  /// Status label.
  final String label;

  /// Semantic status type.
  final AppStatusChipType type;

  /// Overrides [type] with a module tone (e.g. [AppTone.sky] for attendance).
  final AppTone? tone;

  /// Optional icon shown instead of the dot.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveTone = tone ?? type.tone;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: effectiveTone.background,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 13, color: effectiveTone.foreground)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: effectiveTone.foreground,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: effectiveTone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Semantic status types supported by status chips.
enum AppStatusChipType {
  /// Successful or approved status.
  success(AppTone.success),

  /// Pending or needs-attention status.
  warning(AppTone.warning),

  /// Rejected or error status.
  error(AppTone.error),

  /// In progress.
  info(AppTone.sky),

  /// Draft or neutral status.
  neutral(AppTone.neutral);

  const AppStatusChipType(this.tone);

  /// The tone this type renders with.
  final AppTone tone;
}
