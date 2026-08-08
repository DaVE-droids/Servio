import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/activity_repository.dart';
import '../../data/services/activity_service.dart';
import '../../domain/use_cases/get_activity_feed_use_case.dart';
import '../controllers/activity_controller.dart';

/// Provides the activity service placeholder.
final activityServiceProvider = Provider<ActivityService>((ref) {
  return const ActivityService();
});

/// Provides the activity repository placeholder.
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return const ActivityRepository();
});

/// Provides the get activity feed use case placeholder.
final getActivityFeedUseCaseProvider = Provider<GetActivityFeedUseCase>((ref) {
  return GetActivityFeedUseCase(ref.watch(activityRepositoryProvider));
});

/// Provides the activity controller placeholder.
final activityControllerProvider =
    AsyncNotifierProvider<ActivityController, void>(ActivityController.new);
