import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

/// Summary card used on the student dashboard.
class StudentDashboardSummaryCard extends StatelessWidget {
  /// Creates a student dashboard summary card.
  const StudentDashboardSummaryCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  /// Card title.
  final String title;

  /// Primary status value.
  final String value;

  /// Supporting explanatory text.
  final String description;

  /// Leading icon.
  final IconData icon;

  /// Semantic accent color.
  final Color color;

  /// Optional card action label.
  final String? actionLabel;

  /// Optional card action callback.
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: onActionPressed,
            ),
          ],
        ],
      ),
    );
  }
}
