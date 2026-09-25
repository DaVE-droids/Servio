import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// A label on the left and its value on the right, as on the sample's
/// "Gender · Female" rows. Long values wrap under themselves, never under
/// the label.
class InfoRow extends StatelessWidget {
  /// Creates an info row.
  const InfoRow(this.label, this.value, {this.icon, super.key});

  /// Left-hand label.
  final String label;

  /// Right-hand value.
  final String value;

  /// Optional icon before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: AppSpacing.xs),
          ],
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableText(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A group of [InfoRow]s on a sunken panel, divided by hairlines.
class InfoPanel extends StatelessWidget {
  /// Creates an info panel.
  const InfoPanel({required this.rows, super.key});

  /// The rows.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}
