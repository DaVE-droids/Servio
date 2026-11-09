import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/authentication_providers.dart';
import '../widgets/auth_layout.dart';

/// Shown while a signed-in user has not verified their email address.
class EmailVerificationScreen extends ConsumerWidget {
  /// Creates an email verification screen.
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);
    final email =
        ref.watch(authSessionProvider).value?.firebaseUser?.email ??
        'your email address';
    final controller = ref.read(authenticationControllerProvider.notifier);

    ref.listen(authenticationControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      if (message != null &&
          message != (previous?.errorMessage ?? previous?.successMessage)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return AuthLayout(
      eyebrow: 'One more step',
      title: 'Check your inbox',
      subtitle:
          'We sent a verification link to $email. Open it, then come back '
          'and continue.',
      children: [
        const _Hint(
          icon: Icons.mark_email_unread_outlined,
          text:
              'Can’t find it? Check your spam or promotions folder. The link '
              'comes from noreply@servio-e2974.firebaseapp.com.',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'I’ve verified my email',
          isLoading: authState.isLoading,
          onPressed: controller.reloadCurrentUser,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Send the link again',
          variant: AppButtonVariant.secondary,
          onPressed: authState.isLoading
              ? null
              : controller.sendVerificationEmail,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Sign out',
          variant: AppButtonVariant.text,
          onPressed: authState.isLoading ? null : controller.logout,
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTone.sky.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.skyStrong),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkDeep),
            ),
          ),
        ],
      ),
    );
  }
}
