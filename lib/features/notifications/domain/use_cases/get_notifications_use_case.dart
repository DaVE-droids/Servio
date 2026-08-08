import '../../../../core/result/result.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Use case placeholder for loading notifications.
class GetNotificationsUseCase {
  /// Creates a get notifications use case.
  const GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  /// Executes the placeholder load workflow.
  Future<Result<List<NotificationModel>>> call() =>
      _repository.getNotifications();
}
