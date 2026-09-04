/// Notification categories defined by the DDS.
enum NotificationType {
  /// Placement submission, approval, rejection, or lecturer assignment.
  placement,

  /// Attendance check-in and check-out activity.
  attendance,

  /// Logbook submission and review outcomes.
  logbook,

  /// Supervision visit reports.
  supervision,

  /// System-generated messages.
  system,

  /// Institution-wide announcements.
  announcement,
}

/// Serialization helpers for [NotificationType].
extension NotificationTypeSerialization on NotificationType {
  /// Firestore value defined by the DDS.
  String get firestoreValue {
    return switch (this) {
      NotificationType.placement => 'placement',
      NotificationType.attendance => 'attendance',
      NotificationType.logbook => 'logbook',
      NotificationType.supervision => 'supervision',
      NotificationType.system => 'system',
      NotificationType.announcement => 'announcement',
    };
  }

  /// Human-readable label for UI display.
  String get label {
    return switch (this) {
      NotificationType.placement => 'Placement',
      NotificationType.attendance => 'Attendance',
      NotificationType.logbook => 'Logbook',
      NotificationType.supervision => 'Supervision',
      NotificationType.system => 'System',
      NotificationType.announcement => 'Announcement',
    };
  }

  /// Parses a DDS Firestore value into a notification type.
  ///
  /// Falls back to [NotificationType.system] rather than throwing: a
  /// notification is a passive message, and one unrecognized type (say,
  /// written by a newer app version) shouldn't break the whole list.
  static NotificationType fromFirestore(String value) {
    return switch (value) {
      'placement' => NotificationType.placement,
      'attendance' => NotificationType.attendance,
      'logbook' => NotificationType.logbook,
      'supervision' => NotificationType.supervision,
      'system' => NotificationType.system,
      'announcement' => NotificationType.announcement,
      _ => NotificationType.system,
    };
  }
}
