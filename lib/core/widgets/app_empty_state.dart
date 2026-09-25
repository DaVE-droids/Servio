import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tone.dart';
import 'app_button.dart';

/// Shown when there's nothing to list yet. Says what will appear here and,
/// when there is one, offers the action that makes it appear.
class AppEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const AppEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.tone = AppTone.ink,
    this.actionLabel,
    this.onActionPressed,
    this.compact = false,
    super.key,
  });

  /// Empty state title.
  final String title;

  /// Empty state explanation.
  final String message;

  /// Illustrative icon.
  final IconData icon;

  /// Module tone for the icon tile.
  final AppTone tone;

  /// Optional primary action label.
  final String? actionLabel;

  /// Optional primary action callback.
  final VoidCallback? onActionPressed;

  /// Smaller version for use inside a card rather than a whole screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tileSize = compact ? 48.0 : 64.0;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(tileSize * 0.32),
            ),
            child: Icon(icon, color: tone.foreground, size: tileSize * 0.44),
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact ? textTheme.titleMedium : textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel!,
              onPressed: onActionPressed,
              expand: false,
            ),
          ],
        ],
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: content),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}
