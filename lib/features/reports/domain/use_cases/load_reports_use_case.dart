import '../../../../core/result/result.dart';
import '../../data/repositories/reports_repository.dart';

/// Use case placeholder for loading reports.
class LoadReportsUseCase {
  /// Creates a load reports use case.
  const LoadReportsUseCase(this._repository);

  final ReportsRepository _repository;

  /// Executes the placeholder report load workflow.
  Future<Result<void>> call() => _repository.loadReports();
}
