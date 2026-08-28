/// Review states for digital logbook entries.
enum LogbookStatus {
  /// Entry is waiting for review.
  pending,

  /// Entry was approved by a lecturer.
  approved,

  /// Lecturer requested changes.
  changesRequested,
}

/// Serialization helpers for [LogbookStatus].
extension LogbookStatusSerialization on LogbookStatus {
  /// Firestore value defined by the DDS.
  String get firestoreValue {
    return switch (this) {
      LogbookStatus.pending => 'pending',
      LogbookStatus.approved => 'approved',
      LogbookStatus.changesRequested => 'changes_requested',
    };
  }

  /// Human-readable label for UI status display.
  String get label {
    return switch (this) {
      LogbookStatus.pending => 'Pending Review',
      LogbookStatus.approved => 'Approved',
      LogbookStatus.changesRequested => 'Changes Requested',
    };
  }

  /// Parses a DDS Firestore value into a logbook status.
  static LogbookStatus fromFirestore(String value) {
    return switch (value) {
      'pending' => LogbookStatus.pending,
      'approved' => LogbookStatus.approved,
      'changes_requested' => LogbookStatus.changesRequested,
      _ => throw ArgumentError.value(value, 'value', 'Unknown logbook status'),
    };
  }
}
