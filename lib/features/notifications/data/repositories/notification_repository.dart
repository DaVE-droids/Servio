import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/notification_model.dart';

/// Repository placeholder for in-app notification operations.
class NotificationRepository {
  /// Creates a notification repository.
  const NotificationRepository();

  /// Placeholder contract for retrieving notifications.
  Future<Result<List<NotificationModel>>> getNotifications() async {
    return const Failure(
      AppFailure(message: 'Notification logic is not implemented yet.'),
    );
  }
}
