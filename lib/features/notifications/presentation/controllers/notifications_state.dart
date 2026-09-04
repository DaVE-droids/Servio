import '../../data/models/notification_model.dart';

/// UI state for the notifications list.
class NotificationsState {
  /// Creates notifications UI state.
  const NotificationsState({
    this.notifications = const [],
    this.errorMessage,
  });

  /// Notifications, most recent first.
  final List<NotificationModel> notifications;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Number of notifications the user hasn't read yet.
  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  /// Returns a copy with selected fields changed.
  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
    );
  }
}
