import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/auth_requests.dart';
import '../../domain/auth_validator.dart';
import '../providers/authentication_providers.dart';
import '../widgets/auth_layout.dart';

/// Email/password sign-in.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(authenticationControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return AuthLayout(
      eyebrow: 'Welcome back',
      title: 'Sign in to Servio',
      subtitle: 'Use the email you registered with.',
      children: [
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          prefixIcon: Icons.mail_outline,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          errorText: _emailError,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          errorText: _passwordError,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Sign in',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New to Servio?',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final emailError = AuthValidator.email(_emailController.text);
    final passwordError = AuthValidator.password(_passwordController.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) {
      return;
    }

    TextInput.finishAutofillContext();
    await ref
        .read(authenticationControllerProvider.notifier)
        .login(
          LoginRequest(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }
}
