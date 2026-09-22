import '../../../../core/result/result.dart';
import '../../../profile/data/models/user_model.dart';
import '../../data/models/auth_requests.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for email/password self-registration (students and lecturers).
class RegisterUseCase {
  /// Creates a registration use case.
  const RegisterUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Registers an account and its profile.
  Future<Result<UserModel>> call(RegisterRequest request) {
    return _repository.register(request);
  }
}
