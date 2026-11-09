import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/update_decision.dart';
import '../providers/update_providers.dart';

/// Offers a newer build, and installs it.
///
/// A required update has no way out: the running build is too old to be
/// trusted, so there is nothing useful to let the user back to.
class UpdateDialog extends ConsumerWidget {
  /// Creates the update dialog.
  const UpdateDialog({required this.decision, super.key});

  /// What was found, and whether taking it is optional.
  final UpdateDecision decision;

  /// Shows the dialog for [decision].
  static Future<void> show(BuildContext context, UpdateDecision decision) {
    return showDialog<void>(
      context: context,
      barrierDismissible: decision.action == UpdateAction.optional,
      builder: (context) => UpdateDialog(decision: decision),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = decision.config!;
    final download = ref.watch(updateDownloadControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final isRequired = decision.action == UpdateAction.required;

    return PopScope(
      canPop: !isRequired && !download.isRunning,
      child: AlertDialog(
        title: Text(isRequired ? 'Update to continue' : 'Update available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRequired
                  ? 'This version of Servio is too old to work properly. '
                        'Version ${config.latestVersionName} fixes that.'
                  : 'Version ${config.latestVersionName} is ready to '
                        'install.',
              style: textTheme.bodyMedium,
            ),
            if (config.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Text(
                  config.releaseNotes,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
              ),
            ],
            if (download.isRunning) ...[
              const SizedBox(height: AppSpacing.md),
              // Indeterminate while the server hasn't said how big the file
              // is; there is no total to measure against until it does.
              LinearProgressIndicator(
                value: download.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                download.progress == null
                    ? 'Downloading…'
                    : 'Downloading… ${(download.progress! * 100).round()}%',
                style: textTheme.bodySmall,
              ),
            ],
            if (download.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                download.error!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Android will ask you to confirm the install, and may warn '
              'that the app is from an unknown source. That is normal for '
              'an app installed outside the Play Store.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (!isRequired && !download.isRunning)
            AppButton(
              label: 'Later',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
          AppButton(
            label: download.error == null ? 'Update now' : 'Try again',
            icon: Icons.download_rounded,
            isLoading: download.isRunning,
            onPressed: download.isRunning
                ? null
                : () => ref
                      .read(updateDownloadControllerProvider.notifier)
                      .start(config),
          ),
        ],
      ),
    );
  }
}
