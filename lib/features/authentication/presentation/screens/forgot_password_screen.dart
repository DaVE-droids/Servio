import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/auth_validator.dart';
import '../providers/authentication_providers.dart';
import '../widgets/auth_layout.dart';

/// Password reset by email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Creates a forgot password screen.
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationControllerProvider);

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
      eyebrow: 'Password reset',
      title: 'Forgot your password?',
      subtitle:
          'Enter your account email and we’ll send you a link to choose a '
          'new one.',
      children: [
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          prefixIcon: Icons.mail_outline,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _emailError,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Send reset link',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Back to sign in',
          variant: AppButtonVariant.text,
          icon: Icons.arrow_back_rounded,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final emailError = AuthValidator.email(_emailController.text);
    setState(() => _emailError = emailError);
    if (emailError != null) {
      return;
    }
    await ref
        .read(authenticationControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);
  }
}
