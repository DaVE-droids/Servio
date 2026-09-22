import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/models/auth_session.dart';
import '../../data/repositories/authentication_repository.dart';
import '../../data/services/authentication_service.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/reload_current_user_use_case.dart';
import '../../domain/use_cases/send_password_reset_use_case.dart';
import '../../domain/use_cases/send_verification_email_use_case.dart';
import '../controllers/authentication_controller.dart';
import '../controllers/authentication_state.dart';

/// Provides the feature authentication service placeholder.
final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService(ref.watch(firebaseAuthProvider));
});

/// Provides the authentication repository placeholder.
final authenticationRepositoryProvider = Provider<AuthenticationRepository>((
  ref,
) {
  return AuthenticationRepository(
    ref.watch(authenticationServiceProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

/// Provides the login use case placeholder.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authenticationRepositoryProvider));
});

/// Provides the register student use case.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authenticationRepositoryProvider));
});

/// Provides the password reset use case.
final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((
  ref,
) {
  return SendPasswordResetUseCase(ref.watch(authenticationRepositoryProvider));
});

/// Provides the email verification use case.
final sendVerificationEmailUseCaseProvider =
    Provider<SendVerificationEmailUseCase>((ref) {
      return SendVerificationEmailUseCase(
        ref.watch(authenticationRepositoryProvider),
      );
    });

/// Provides the current user reload use case.
final reloadCurrentUserUseCaseProvider = Provider<ReloadCurrentUserUseCase>((
  ref,
) {
  return ReloadCurrentUserUseCase(ref.watch(authenticationRepositoryProvider));
});

/// Provides the logout use case.
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authenticationRepositoryProvider));
});

/// Provides the persisted authentication session stream.
final authSessionProvider = StreamProvider<AuthSession>((ref) {
  return ref.watch(authenticationRepositoryProvider).authSessionChanges();
});

/// Provides the authentication controller placeholder.
final authenticationControllerProvider =
    NotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
    );
