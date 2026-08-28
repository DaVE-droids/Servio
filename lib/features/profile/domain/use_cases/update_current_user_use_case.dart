import '../../../../core/result/result.dart';
import '../../data/models/profile_update_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Use case for saving permitted current-user profile changes.
class UpdateCurrentUserUseCase {
  /// Creates an update current user use case.
  const UpdateCurrentUserUseCase(this._repository);

  final ProfileRepository _repository;

  /// Saves current-user profile changes.
  Future<Result<UserModel>> call({
    required String uid,
    required ProfileUpdateRequest request,
  }) {
    return _repository.updateCurrentUser(uid: uid, request: request);
  }
}
