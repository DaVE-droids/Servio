import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/notification_type.dart';

/// Firestore model for documents in `notifications`.
class NotificationModel {
  /// Creates a notification model.
  const NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  /// Notification document ID.
  final String notificationId;

  /// Recipient user ID.
  final String recipientId;

  /// Recipient role at the time the notification was created.
  final String recipientRole;

  /// User who triggered the notification, if a person did.
  final String? senderId;

  /// Denormalized sender name, per the DDS's denormalization policy.
  final String? senderName;

  /// Notification title.
  final String title;

  /// Notification body.
  final String message;

  /// Notification category.
  final NotificationType type;

  /// Related document ID, so tapping a notification can deep-link later.
  final String? relatedEntityId;

  /// Related entity type (internship, logbook_entry, etc.).
  final String? relatedEntityType;

  /// Whether the recipient has read this notification. The only field that
  /// may ever change — notifications are otherwise immutable.
  final bool isRead;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates a notification from JSON.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      recipientId: json['recipientId'] as String,
      recipientRole: json['recipientRole'] as String? ?? '',
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationTypeSerialization.fromFirestore(
        json['type'] as String? ?? 'system',
      ),
      relatedEntityId: json['relatedEntityId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'senderId': senderId,
      'senderName': senderName,
      'title': title,
      'message': message,
      'type': type.firestoreValue,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }

  /// Returns a copy with the read flag changed — the only mutable field.
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: recipientId,
      recipientRole: recipientRole,
      senderId: senderId,
      senderName: senderName,
      title: title,
      message: message,
      type: type,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

DateTime _readDateTime(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    String text => DateTime.parse(text).toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };
}
