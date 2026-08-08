import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository.dart';
import '../../data/services/profile_service.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../controllers/profile_controller.dart';

/// Provides the profile service placeholder.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return const ProfileService();
});

/// Provides the profile repository placeholder.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const ProfileRepository();
});

/// Provides the get current user use case placeholder.
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(profileRepositoryProvider));
});

/// Provides the profile controller placeholder.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);
