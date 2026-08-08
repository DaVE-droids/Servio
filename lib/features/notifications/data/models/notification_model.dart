/// Firestore model placeholder for documents in `notifications`.
class NotificationModel {
  /// Creates a notification model.
  const NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  /// Notification document ID.
  final String notificationId;

  /// Recipient user ID.
  final String recipientId;

  /// Notification title.
  final String title;

  /// Notification body.
  final String message;

  /// Whether the notification has been read.
  final bool isRead;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates a notification from JSON.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      recipientId: json['recipientId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy with selected fields changed.
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: recipientId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
