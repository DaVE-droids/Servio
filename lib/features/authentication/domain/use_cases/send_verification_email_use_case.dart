import '../../../../core/result/result.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for resending email verification.
class SendVerificationEmailUseCase {
  /// Creates an email verification use case.
  const SendVerificationEmailUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Sends a verification email to the current user.
  Future<Result<void>> call() {
    return _repository.sendVerificationEmail();
  }
}
