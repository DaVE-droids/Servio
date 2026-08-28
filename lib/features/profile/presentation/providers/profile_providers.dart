import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/result/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/profile_service.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../domain/use_cases/update_current_user_use_case.dart';
import '../../domain/use_cases/upload_profile_photo_use_case.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';

/// Provides the profile service placeholder.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

/// Provides the profile repository placeholder.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(profileServiceProvider));
});

/// Provides the get current user use case placeholder.
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(profileRepositoryProvider));
});

/// Provides the update current user use case.
final updateCurrentUserUseCaseProvider = Provider<UpdateCurrentUserUseCase>((
  ref,
) {
  return UpdateCurrentUserUseCase(ref.watch(profileRepositoryProvider));
});

/// Provides the upload profile photo use case.
final uploadProfilePhotoUseCaseProvider = Provider<UploadProfilePhotoUseCase>((
  ref,
) {
  return UploadProfilePhotoUseCase(ref.watch(profileRepositoryProvider));
});

/// Provides the profile controller placeholder.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileState>(
      ProfileController.new,
    );

/// Provides the lecturer roster for coordinator assignment pickers.
final lecturersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getLecturers();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
