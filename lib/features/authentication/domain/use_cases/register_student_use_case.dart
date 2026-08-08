import '../../../../core/result/result.dart';
import '../../../profile/data/models/user_model.dart';
import '../../data/models/auth_requests.dart';
import '../../data/repositories/authentication_repository.dart';

/// Use case for student email/password registration.
class RegisterStudentUseCase {
  /// Creates a registration use case.
  const RegisterStudentUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Registers a student account and profile.
  Future<Result<UserModel>> call(RegisterRequest request) {
    return _repository.registerStudent(request);
  }
}
