import '../../../../core/result/result.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for signing out.
class LogoutUseCase {
  /// Creates a logout use case.
  const LogoutUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Signs out the current user.
  Future<Result<void>> call() {
    return _repository.logout();
  }
}
