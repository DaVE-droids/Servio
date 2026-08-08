import '../../../../core/result/result.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for sending forgot-password emails.
class SendPasswordResetUseCase {
  /// Creates a password reset use case.
  const SendPasswordResetUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Sends a password reset email.
  Future<Result<void>> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
