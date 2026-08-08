import '../../../../core/result/result.dart';
import '../../data/models/supervision_report_model.dart';
import '../../data/repositories/supervision_repository.dart';

/// Use case placeholder for supervision report creation.
class CreateSupervisionReportUseCase {
  /// Creates a supervision report use case.
  const CreateSupervisionReportUseCase(this._repository);

  final SupervisionRepository _repository;

  /// Executes the placeholder report workflow.
  Future<Result<List<SupervisionReportModel>>> call() =>
      _repository.getReports();
}
