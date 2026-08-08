import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

/// Repository placeholder for coordinator reports.
class ReportsRepository {
  /// Creates a reports repository.
  const ReportsRepository();

  /// Placeholder contract for loading reports.
  Future<Result<void>> loadReports() async {
    return const Failure(
      AppFailure(message: 'Reports logic is not implemented yet.'),
    );
  }
}
