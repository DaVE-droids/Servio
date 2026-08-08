import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/supervision_report_model.dart';

/// Repository placeholder for lecturer supervision operations.
class SupervisionRepository {
  /// Creates a supervision repository.
  const SupervisionRepository();

  /// Placeholder contract for retrieving supervision reports.
  Future<Result<List<SupervisionReportModel>>> getReports() async {
    return const Failure(
      AppFailure(message: 'Supervision logic is not implemented yet.'),
    );
  }
}
