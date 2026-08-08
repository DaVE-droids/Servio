/// Firestore model placeholder for documents in `audit_events`.
class AuditEventModel {
  /// Creates an audit event model.
  const AuditEventModel({
    required this.eventId,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
  });

  /// Audit event document ID.
  final String eventId;

  /// Actor user ID or SYSTEM.
  final String actorId;

  /// Actor role.
  final String actorRole;

  /// Action performed.
  final String action;

  /// Affected entity type.
  final String entityType;

  /// Affected entity ID.
  final String entityId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates an audit event from JSON.
  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      eventId: json['eventId'] as String,
      actorId: json['actorId'] as String,
      actorRole: json['actorRole'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'actorId': actorId,
      'actorRole': actorRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns this event unchanged because audit events are immutable.
  AuditEventModel copyWith() => this;
}
