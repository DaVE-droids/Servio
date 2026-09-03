import '../../../../core/result/result.dart';
import '../../data/models/supervision_report_model.dart';
import '../../data/repositories/supervision_repository.dart';

/// Use case for retrieving a lecturer's submitted visit reports.
class GetReportsUseCase {
  /// Creates a get reports use case.
  const GetReportsUseCase(this._repository);

  final SupervisionRepository _repository;

  /// Retrieves this lecturer's visit reports, most recent first.
  Future<Result<List<SupervisionReportModel>>> call(String lecturerId) {
    return _repository.getReports(lecturerId);
  }
}
