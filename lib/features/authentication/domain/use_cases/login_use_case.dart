import '../../../../core/result/result.dart';
import '../../../profile/data/models/user_model.dart';
import '../../data/models/auth_requests.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case placeholder for the login workflow.
class LoginUseCase {
  /// Creates a login use case.
  const LoginUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Executes the login workflow.
  Future<Result<UserModel>> call(LoginRequest request) =>
      _repository.login(request);
}
