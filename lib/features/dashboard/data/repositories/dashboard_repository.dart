import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

/// Repository placeholder for role-specific dashboard summaries.
class DashboardRepository {
  /// Creates a dashboard repository.
  const DashboardRepository();

  /// Placeholder contract for loading dashboard data.
  Future<Result<void>> loadDashboard() async {
    return const Failure(
      AppFailure(message: 'Dashboard logic is not implemented yet.'),
    );
  }
}
