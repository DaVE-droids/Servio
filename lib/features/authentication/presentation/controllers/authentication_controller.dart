import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../data/models/auth_requests.dart';
import '../providers/authentication_providers.dart';
import 'authentication_state.dart';

/// Controller for authentication UI state and actions.
class AuthenticationController extends Notifier<AuthenticationState> {
  /// Builds the initial authentication state.
  @override
  AuthenticationState build() => const AuthenticationState();

  /// Registers a student account.
  Future<bool> register(RegisterRequest request) {
    return _run(() => ref.read(registerStudentUseCaseProvider).call(request));
  }

  /// Logs in with email/password.
  Future<bool> login(LoginRequest request) {
    return _run(() => ref.read(loginUseCaseProvider).call(request));
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordReset(String email) {
    return _run(
      () => ref.read(sendPasswordResetUseCaseProvider).call(email),
      successMessage: 'Password reset email sent.',
    );
  }

  /// Resends email verification.
  Future<bool> sendVerificationEmail() {
    return _run(
      () => ref.read(sendVerificationEmailUseCaseProvider).call(),
      successMessage: 'Verification email sent.',
    );
  }

  /// Reloads the current user's verification state.
  Future<bool> reloadCurrentUser() {
    return _run(() => ref.read(reloadCurrentUserUseCaseProvider).call());
  }

  /// Signs out the current user.
  Future<bool> logout() {
    return _run(() => ref.read(logoutUseCaseProvider).call());
  }

  Future<bool> _run<T>(
    Future<Result<T>> Function() action, {
    String? successMessage,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final result = await action();
    switch (result) {
      case Success<T>():
        state = state.copyWith(
          isLoading: false,
          successMessage: successMessage,
          clearMessages: successMessage == null,
        );
        return true;
      case Failure<T>(:final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }
}
