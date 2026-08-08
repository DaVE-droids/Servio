import '../../../../core/result/result.dart';
import '../../data/repositories/settings_repository.dart';

/// Use case placeholder for loading settings.
class LoadSettingsUseCase {
  /// Creates a load settings use case.
  const LoadSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  /// Executes the placeholder settings load workflow.
  Future<Result<void>> call() => _repository.loadSettings();
}
