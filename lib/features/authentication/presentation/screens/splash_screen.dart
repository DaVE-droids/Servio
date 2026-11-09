import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../providers/authentication_providers.dart';

/// Shown for the moment between launch and the auth session resolving.
///
/// Matches the native launch screen (a centred mark on white), so opening
/// the app is one continuous image rather than a flash between two. The
/// router sends every path here while the session loads, then on to
/// sign-in or the right home.
///
/// If the session can't be resolved at all — the account lookup failed
/// even after retrying — this offers a way out rather than leaving someone
/// watching a progress bar that will never finish.
class SplashScreen extends ConsumerWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    // Riverpod keeps retrying a failed stream in the background, so it
    // reports loading and error at the same time. Any error means the
    // account lookup has already failed once, which is the point to stop
    // showing a progress bar and offer a way out.
    final isStuck = session.hasError;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 96),
                const SizedBox(height: 28),
                if (!isStuck)
                  const SizedBox(
                    width: 96,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  )
                else ...[
                  Text(
                    'We couldn’t load your account',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Try again',
                    onPressed: () => ref.invalidate(authSessionProvider),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: 'Sign out',
                    variant: AppButtonVariant.text,
                    isLoading: ref
                        .watch(authenticationControllerProvider)
                        .isLoading,
                    onPressed: () => ref
                        .read(authenticationControllerProvider.notifier)
                        .logout(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
