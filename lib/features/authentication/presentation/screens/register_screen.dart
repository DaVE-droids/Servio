import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/auth_requests.dart';
import '../../domain/auth_validator.dart';
import '../providers/authentication_providers.dart';

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

    ref.listen(authenticationControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Create your account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.student,
                    label: Text('Student'),
                    icon: Icon(Icons.school_outlined),
                  ),
                  ButtonSegment(
                    value: UserRole.lecturer,
                    label: Text('Lecturer'),
                    icon: Icon(Icons.badge_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (selection) => setState(() {
                  _role = selection.first;
                  _errors.remove('matricNumber');
                }),
              ),
              if (_isLecturer) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Lecturer accounts are reviewed by a coordinator before '
                  'they can be used. You will be able to sign in, and your '
                  'access starts once you are approved.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'First Name',
                controller: _firstNameController,
                errorText: _errors['firstName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Last Name',
                controller: _lastNameController,
                errorText: _errors['lastName'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                errorText: _errors['email'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                errorText: _errors['password'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Department',
                controller: _departmentController,
                errorText: _errors['department'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: _isLecturer ? 'Staff ID' : 'Matric Number',
                controller: _matricNumberController,
                errorText: _errors['matricNumber'],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: 'Faculty', controller: _facultyController),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Create Account',
                isLoading: authState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Back to Login',
                variant: AppButtonVariant.text,
                onPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
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
