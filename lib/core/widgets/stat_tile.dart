import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tone.dart';
import '../../app/theme/app_typography.dart';

/// A number that matters, with what it counts: "12 · Active placements".
///
/// A [highlighted] tile is filled with its tone — use it for the one figure
/// a screen is really about, and keep the rest plain.
class StatTile extends StatelessWidget {
  /// Creates a stat tile.
  const StatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.tone = AppTone.ink,
    this.highlighted = false,
    this.caption,
    this.onTap,
    super.key,
  });

  /// The figure, already formatted.
  final String value;

  /// What the figure counts.
  final String label;

  /// Badge icon.
  final IconData icon;

  /// Module or outcome tone.
  final AppTone tone;

  /// Fills the tile with its tone.
  final bool highlighted;

  /// Optional extra line, e.g. "3 need a visit".
  final String? caption;

  /// Optional drill-down.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final background = highlighted ? tone.fill : AppColors.surface;
    final badgeColor = highlighted ? AppColors.surface : tone.background;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: highlighted ? Colors.transparent : AppColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 30,
                            color: AppColors.inkDeep,
                            fontFeatures: AppTypography.tabular,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: tone.foreground),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: highlighted
                      ? AppColors.inkDeep.withValues(alpha: 0.75)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: tone.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays stat tiles out two-up on phones and up to [maxColumns] across on
/// wider screens.
class StatGrid extends StatelessWidget {
  /// Creates a stat grid.
  const StatGrid({required this.children, this.maxColumns = 4, super.key});

  /// The tiles.
  final List<Widget> children;

  /// Most tiles in one row.
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width >= 900 ? maxColumns : 2).clamp(
          1,
          children.length,
        );
        const gap = AppSpacing.sm;
        final tileWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
