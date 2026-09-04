import '../../../../core/result/result.dart';
import '../../data/repositories/notification_repository.dart';

/// Marks notifications as read.
class MarkNotificationReadUseCase {
  /// Creates a mark-notification-read use case.
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  /// Marks a single notification as read.
  Future<Result<void>> one(String notificationId) =>
      _repository.markAsRead(notificationId);

  /// Marks every unread notification for a recipient as read.
  Future<Result<void>> all(String recipientId) =>
      _repository.markAllAsRead(recipientId);
}
