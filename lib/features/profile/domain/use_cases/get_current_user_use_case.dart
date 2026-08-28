import '../../../../core/result/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Use case placeholder for loading the current user profile.
class GetCurrentUserUseCase {
  /// Creates a get current user use case.
  const GetCurrentUserUseCase(this._repository);

  final ProfileRepository _repository;

  /// Loads the current user's profile.
  Future<Result<UserModel>> call(String uid) => _repository.getCurrentUser(uid);
}
