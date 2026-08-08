import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/authentication_providers.dart';

/// Screen shown while a signed-in user has not verified their email address.
class EmailVerificationScreen extends ConsumerWidget {
  /// Creates an email verification screen.
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);
    final session = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final email = session?.firebaseUser?.email ?? 'your email address';

    ref.listen(authenticationControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A verification link has been sent to $email. Verify your email, then refresh your session.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'I Have Verified',
                  isLoading: authState.isLoading,
                  onPressed: () {
                    ref
                        .read(authenticationControllerProvider.notifier)
                        .reloadCurrentUser();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Resend Email',
                  variant: AppButtonVariant.secondary,
                  isLoading: authState.isLoading,
                  onPressed: () {
                    ref
                        .read(authenticationControllerProvider.notifier)
                        .sendVerificationEmail();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.text,
                  onPressed: () {
                    ref
                        .read(authenticationControllerProvider.notifier)
                        .logout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
