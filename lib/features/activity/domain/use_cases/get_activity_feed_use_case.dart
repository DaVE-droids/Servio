import '../../../../core/result/result.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/repositories/activity_repository.dart';

/// Use case placeholder for loading the activity feed.
class GetActivityFeedUseCase {
  /// Creates a get activity feed use case.
  const GetActivityFeedUseCase(this._repository);

  final ActivityRepository _repository;

  /// Executes the placeholder activity load workflow.
  Future<Result<List<ActivityLogModel>>> call() =>
      _repository.getActivityFeed();
}
