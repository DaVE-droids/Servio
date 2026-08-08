/// Firestore model placeholder for documents in `activity_logs`.
class ActivityLogModel {
  /// Creates an activity log model.
  const ActivityLogModel({
    required this.activityId,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  /// Activity document ID.
  final String activityId;

  /// Owner user ID.
  final String userId;

  /// Activity title.
  final String title;

  /// Activity message.
  final String message;

  /// Whether the activity has been read.
  final bool isRead;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates an activity log from JSON.
  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      activityId: json['activityId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'userId': userId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy with selected fields changed.
  ActivityLogModel copyWith({bool? isRead}) {
    return ActivityLogModel(
      activityId: activityId,
      userId: userId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
