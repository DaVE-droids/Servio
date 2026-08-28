import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../data/models/profile_photo_upload_request.dart';
import '../../data/models/profile_update_request.dart';
import '../../data/models/user_model.dart';
import '../providers/profile_providers.dart';
import 'profile_state.dart';

/// Controller for profile UI state and profile actions.
class ProfileController extends AsyncNotifier<ProfileState> {
  /// Builds the initial profile state by loading the signed-in user's profile.
  @override
  Future<ProfileState> build() async {
    return _loadProfile();
  }

  /// Refreshes the current user's profile.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadProfile);
  }

  /// Saves permitted profile changes.
  Future<bool> save(ProfileUpdateRequest request) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const ProfileState(),
    };
    state = AsyncData(previous.copyWith(isSaving: true, clearMessages: true));

    final uid = _currentUid();
    if (uid == null) {
      state = AsyncData(
        previous.copyWith(
          isSaving: false,
          errorMessage: 'Your session has expired. Please sign in again.',
        ),
      );
      return false;
    }

    final result = await ref
        .read(updateCurrentUserUseCaseProvider)
        .call(uid: uid, request: request);

    switch (result) {
      case Success<UserModel>(:final data):
        state = AsyncData(
          previous.copyWith(
            user: data,
            isSaving: false,
            successMessage: 'Profile updated successfully.',
            lastLoadedAt: DateTime.now().toUtc(),
          ),
        );
        return true;
      case Failure<UserModel>(:final error):
        state = AsyncData(
          previous.copyWith(isSaving: false, errorMessage: error.message),
        );
        return false;
    }
  }

  /// Uploads and saves the current user's profile photo.
  Future<bool> uploadProfilePhoto(ProfilePhotoUploadRequest request) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const ProfileState(),
    };
    state = AsyncData(
      previous.copyWith(isUploadingPhoto: true, clearMessages: true),
    );

    final uid = _currentUid();
    if (uid == null) {
      state = AsyncData(
        previous.copyWith(
          isUploadingPhoto: false,
          errorMessage: 'Your session has expired. Please sign in again.',
        ),
      );
      return false;
    }

    final result = await ref
        .read(uploadProfilePhotoUseCaseProvider)
        .call(uid: uid, request: request);

    switch (result) {
      case Success<UserModel>(:final data):
        state = AsyncData(
          previous.copyWith(
            user: data,
            isUploadingPhoto: false,
            successMessage: 'Profile photo updated successfully.',
            lastLoadedAt: DateTime.now().toUtc(),
          ),
        );
        return true;
      case Failure<UserModel>(:final error):
        state = AsyncData(
          previous.copyWith(
            isUploadingPhoto: false,
            errorMessage: error.message,
          ),
        );
        return false;
    }
  }

  Future<ProfileState> _loadProfile() async {
    final uid = _currentUid();
    if (uid == null) {
      return const ProfileState(
        errorMessage: 'Your session has expired. Please sign in again.',
      );
    }

    final result = await ref.read(getCurrentUserUseCaseProvider).call(uid);
    switch (result) {
      case Success<UserModel>(:final data):
        return ProfileState(user: data, lastLoadedAt: DateTime.now().toUtc());
      case Failure<UserModel>(:final error):
        return ProfileState(errorMessage: error.message);
    }
  }

  String? _currentUid() {
    final session = switch (ref.read(authSessionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return session?.firebaseUser?.uid;
  }
}
