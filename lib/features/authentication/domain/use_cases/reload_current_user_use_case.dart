import '../../../../core/result/result.dart';
import '../../data/models/auth_session.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for refreshing Firebase email verification state.
class ReloadCurrentUserUseCase {
  /// Creates a reload current user use case.
  const ReloadCurrentUserUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Reloads the current user and resolved session.
  Future<Result<AuthSession>> call() {
    return _repository.reloadCurrentUser();
  }
}
