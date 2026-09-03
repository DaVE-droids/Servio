import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for documents in `audit_events`.
class AuditEventModel {
  /// Creates an audit event model.
  const AuditEventModel({
    required this.eventId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.createdAt,
    this.targetUserId,
    this.metadata,
  });

  /// Audit event document ID.
  final String eventId;

  /// User who performed the action.
  final String actorId;

  /// Denormalized actor name.
  final String actorName;

  /// Actor role (student / lecturer / coordinator).
  final String actorRole;

  /// Action performed.
  final String action;

  /// Affected entity type (internship, attendance, user, etc.).
  final String entityType;

  /// Related document ID.
  final String entityId;

  /// User affected by the action, if different from the actor.
  final String? targetUserId;

  /// Human-readable summary.
  final String description;

  /// Additional structured details.
  final Map<String, dynamic>? metadata;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates an audit event from JSON.
  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      eventId: json['eventId'] as String,
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      actorRole: json['actorRole'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      targetUserId: json['targetUserId'] as String?,
      description: json['description'] as String,
      metadata: (json['metadata'] as Map<String, dynamic>?),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'targetUserId': targetUserId,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }

  /// Returns this event unchanged because audit events are immutable.
  AuditEventModel copyWith() => this;
}

DateTime _readDateTime(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    String text => DateTime.parse(text).toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };
}
