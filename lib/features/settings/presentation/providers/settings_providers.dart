import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/services/settings_service.dart';
import '../../domain/use_cases/load_settings_use_case.dart';
import '../controllers/settings_controller.dart';

/// Provides the settings service placeholder.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return const SettingsService();
});

/// Provides the settings repository placeholder.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return const SettingsRepository();
});

/// Provides the load settings use case placeholder.
final loadSettingsUseCaseProvider = Provider<LoadSettingsUseCase>((ref) {
  return LoadSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

/// Provides the settings controller placeholder.
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>(SettingsController.new);
