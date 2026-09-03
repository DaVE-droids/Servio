import '../../data/models/user_model.dart';

/// UI state for the profile screen.
class ProfileState {
  /// Creates profile UI state.
  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingPhoto = false,
    this.errorMessage,
    this.successMessage,
    this.lastLoadedAt,
  });

  /// Loaded user profile.
  final UserModel? user;

  /// Whether the initial profile load is in progress.
  final bool isLoading;

  /// Whether profile changes are being saved.
  final bool isSaving;

  /// Whether profile photo upload is in progress.
  final bool isUploadingPhoto;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Last successful profile refresh timestamp.
  final DateTime? lastLoadedAt;

  /// Returns a copy with selected fields changed.
  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingPhoto,
    String? errorMessage,
    String? successMessage,
    DateTime? lastLoadedAt,
    bool clearMessages = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}
