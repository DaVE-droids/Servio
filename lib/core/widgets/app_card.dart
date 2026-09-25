import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';

/// A flat white card with a hairline border — Servio's basic surface.
///
/// Pass [onTap] to make the whole card a target; it then gets a hover and
/// press state instead of looking like static content.
class AppCard extends StatelessWidget {
  /// Creates an app card.
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Makes the card tappable.
  final VoidCallback? onTap;

  /// Background colour.
  final Color color;

  /// Border colour.
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              hoverColor: AppColors.mist.withValues(alpha: 0.6),
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

/// A card with a title row — the sample's "Academic Performance ···" block.
class SectionCard extends StatelessWidget {
  /// Creates a section card.
  const SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  /// Section title.
  final String title;

  /// Optional line under the title.
  final String? subtitle;

  /// Optional action at the end of the title row, e.g. "View all".
  final Widget? trailing;

  /// Section content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
