import '../../../../core/result/result.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Loads a user's notifications, most recent first.
class GetNotificationsUseCase {
  /// Creates a get notifications use case.
  const GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  /// Executes the lookup.
  Future<Result<List<NotificationModel>>> call(String recipientId) =>
      _repository.getNotifications(recipientId);
}
