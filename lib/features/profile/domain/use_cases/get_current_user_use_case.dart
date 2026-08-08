import '../../../../core/result/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Use case placeholder for loading the current user profile.
class GetCurrentUserUseCase {
  /// Creates a get current user use case.
  const GetCurrentUserUseCase(this._repository);

  final ProfileRepository _repository;

  /// Executes the placeholder profile load workflow.
  Future<Result<UserModel>> call() => _repository.getCurrentUser();
}
