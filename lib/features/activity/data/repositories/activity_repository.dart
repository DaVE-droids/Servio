import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/activity_log_model.dart';

/// Repository placeholder for user-facing activity feed reads.
class ActivityRepository {
  /// Creates an activity repository.
  const ActivityRepository();

  /// Placeholder contract for loading activity logs.
  Future<Result<List<ActivityLogModel>>> getActivityFeed() async {
    return const Failure(
      AppFailure(message: 'Activity logic is not implemented yet.'),
    );
  }
}
