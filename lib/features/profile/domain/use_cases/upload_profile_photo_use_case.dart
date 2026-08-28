import '../../../../core/result/result.dart';
import '../../data/models/profile_photo_upload_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Use case for uploading and saving the current user's profile photo.
class UploadProfilePhotoUseCase {
  /// Creates an upload profile photo use case.
  const UploadProfilePhotoUseCase(this._repository);

  final ProfileRepository _repository;

  /// Uploads a profile photo and returns the updated profile.
  Future<Result<UserModel>> call({
    required String uid,
    required ProfilePhotoUploadRequest request,
  }) {
    return _repository.uploadProfilePhoto(uid: uid, request: request);
  }
}
