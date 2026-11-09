import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/authentication_providers.dart';
import '../widgets/auth_layout.dart';

/// Shown to a lecturer who has signed up but hasn't been approved by a
/// coordinator yet.
///
/// This screen is a courtesy, not the protection: the Firestore rules give
/// an unapproved lecturer no lecturer permissions at all, so even a
/// modified app couldn't read student data from here.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  /// Creates the pending approval screen.
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  var _checking = false;

  @override
  Widget build(BuildContext context) {
    final email =
        ref.watch(authSessionProvider).value?.firebaseUser?.email ??
        'your account';

    return AuthLayout(
      eyebrow: 'Almost there',
      title: 'Your account is waiting for approval',
      subtitle:
          'A coordinator needs to approve $email before you can supervise '
          'students. You’ll get a notification as soon as that happens.',
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppTone.warning.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Approval usually happens within a working day. If it’s '
                  'urgent, contact your department’s placement coordinator.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkDeep),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Check again',
          isLoading: _checking,
          onPressed: _checkAgain,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Sign out',
          variant: AppButtonVariant.text,
          isLoading: ref.watch(authenticationControllerProvider).isLoading,
          onPressed: () =>
              ref.read(authenticationControllerProvider.notifier).logout(),
        ),
      ],
    );
  }

  /// Re-reads the profile, which is where approval lands. Approval doesn't
  /// change anything on the Firebase Auth user, so a token refresh would
  /// never notice it. If still unapproved, says so instead of appearing to
  /// do nothing; if approved, the router moves on by itself.
  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    ref.invalidate(authSessionProvider);
    final session = await ref.read(authSessionProvider.future);
    if (!mounted) {
      return;
    }
    setState(() => _checking = false);
    if (session.isAwaitingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not approved yet. We’ll notify you.')),
      );
    }
  }
}
