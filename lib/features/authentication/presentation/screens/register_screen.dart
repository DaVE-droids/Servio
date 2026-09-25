import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/auth_requests.dart';
import '../../domain/auth_validator.dart';
import '../providers/authentication_providers.dart';
import '../widgets/auth_layout.dart';

/// Email/password registration for students and lecturers.
///
/// Lecturer accounts are created inactive and must be approved by a
/// coordinator before they can do anything; the form says so up front so a
/// lecturer isn't surprised by the "awaiting approval" screen afterwards.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates a registration screen.
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _matricNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyController = TextEditingController();
  var _role = UserRole.student;

  bool get _isLecturer => _role == UserRole.lecturer;
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _matricNumberController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
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

    Widget pair(Widget first, Widget second) => LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 420
          ? Column(
              children: [
                first,
                const SizedBox(height: AppSpacing.sm),
                second,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: first),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: second),
              ],
            ),
    );

    return AuthLayout(
      eyebrow: 'Get started',
      title: 'Create your account',
      subtitle:
          'Takes about a minute. We’ll send a link to confirm your email.',
      maxFormWidth: 520,
      children: [
        SegmentedButton<UserRole>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: UserRole.student,
              label: Text('I’m a student'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: UserRole.lecturer,
              label: Text('I’m a lecturer'),
              icon: Icon(Icons.badge_outlined),
            ),
          ],
          selected: {_role},
          onSelectionChanged: (selection) => setState(() {
            _role = selection.first;
            _errors.remove('matricNumber');
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isLecturer
              ? Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppTone.sky.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.skyStrong,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'A coordinator approves lecturer accounts before '
                          'they can see students. You can sign in straight '
                          'away; access starts once you’re approved.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.inkDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.md),
        pair(
          AppTextField(
            label: 'First name',
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            textInputAction: TextInputAction.next,
            errorText: _errors['firstName'],
          ),
          AppTextField(
            label: 'Last name',
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.familyName],
            textInputAction: TextInputAction.next,
            errorText: _errors['lastName'],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          prefixIcon: Icons.mail_outline,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          errorText: _errors['email'],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          autofillHints: const [AutofillHints.newPassword],
          helperText: 'At least 8 characters.',
          textInputAction: TextInputAction.next,
          errorText: _errors['password'],
        ),
        const SizedBox(height: AppSpacing.sm),
        pair(
          AppTextField(
            label: 'Department',
            controller: _departmentController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: _errors['department'],
          ),
          AppTextField(
            label: _isLecturer ? 'Staff ID' : 'Matric number',
            controller: _matricNumberController,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            errorText: _errors['matricNumber'],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        pair(
          AppTextField(
            label: 'Phone (optional)',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            label: 'Faculty (optional)',
            controller: _facultyController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Create account',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            style: textTheme.bodySmall,
            children: [
              const TextSpan(text: 'By creating an account you agree to the '),
              TextSpan(
                text: 'Terms',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      openExternalLink(context, AppConstants.termsUrl),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      openExternalLink(context, AppConstants.privacyPolicyUrl),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final errors = {
      'firstName': AuthValidator.required(
        _firstNameController.text,
        'First name',
      ),
      'lastName': AuthValidator.required(_lastNameController.text, 'Last name'),
      'email': AuthValidator.email(_emailController.text),
      'password': AuthValidator.password(_passwordController.text),
      'department': AuthValidator.required(
        _departmentController.text,
        'Department',
      ),
      'matricNumber': AuthValidator.required(
        _matricNumberController.text,
        _isLecturer ? 'Staff ID' : 'Matric number',
      ),
    };
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((message) => message != null)) {
      return;
    }

    await ref
        .read(authenticationControllerProvider.notifier)
        .register(
          RegisterRequest(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            department: _departmentController.text,
            idNumber: _matricNumberController.text,
            role: _role,
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text,
            faculty: _facultyController.text.trim().isEmpty
                ? null
                : _facultyController.text,
          ),
        );
  }
}
