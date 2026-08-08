import '../../../../core/result/result.dart';
import '../../data/repositories/dashboard_repository.dart';

/// Use case placeholder for loading dashboard summaries.
class LoadDashboardUseCase {
  /// Creates a load dashboard use case.
  const LoadDashboardUseCase(this._repository);

  final DashboardRepository _repository;

  /// Executes the placeholder dashboard load workflow.
  Future<Result<void>> call() => _repository.loadDashboard();
}
