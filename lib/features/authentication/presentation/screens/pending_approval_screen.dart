import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/authentication_providers.dart';

/// Shown to a lecturer who has signed up but hasn't been approved by a
/// coordinator yet.
///
/// This screen is a courtesy, not the protection: the Firestore rules give
/// an unapproved lecturer no lecturer permissions at all, so even a
/// modified app couldn't read student data from here.
class PendingApprovalScreen extends ConsumerWidget {
  /// Creates the pending approval screen.
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final email = session?.firebaseUser?.email ?? 'your account';

    return Scaffold(
      appBar: AppBar(title: const Text('Awaiting Approval')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.hourglass_top_outlined, size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your lecturer account is being reviewed',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A coordinator needs to approve $email before you can '
                  'supervise students. You will get a notification once '
                  'you are approved.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Check Again',
                  // Re-subscribing to the session re-reads the profile, which
                  // is where the approval lands. Approval doesn't change
                  // anything on the Firebase Auth user itself, so a plain
                  // token refresh would never notice it.
                  onPressed: () => ref.invalidate(authSessionProvider),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.text,
                  onPressed: () => ref
                      .read(authenticationControllerProvider.notifier)
                      .logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
