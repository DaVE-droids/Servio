/// Lifecycle states for internship placement records.
enum InternshipStatus {
  /// Placement is being prepared.
  draft,

  /// Placement has been submitted for review.
  pendingReview,

  /// Placement has been approved.
  approved,

  /// Placement has been rejected by a coordinator.
  rejected,

  /// Lecturer has been assigned.
  assigned,

  /// Internship is active.
  active,

  /// Internship has been completed.
  completed,

  /// Internship has been archived.
  archived,
}

/// Serialization helpers for [InternshipStatus].
extension InternshipStatusSerialization on InternshipStatus {
  /// Firestore value defined by the DDS.
  String get firestoreValue {
    return switch (this) {
      InternshipStatus.draft => 'draft',
      InternshipStatus.pendingReview => 'pending_review',
      InternshipStatus.approved => 'approved',
      InternshipStatus.rejected => 'rejected',
      InternshipStatus.assigned => 'assigned',
      InternshipStatus.active => 'active',
      InternshipStatus.completed => 'completed',
      InternshipStatus.archived => 'archived',
    };
  }

  /// Human-readable label for UI status display.
  String get label {
    return switch (this) {
      InternshipStatus.draft => 'Draft',
      InternshipStatus.pendingReview => 'Pending Review',
      InternshipStatus.approved => 'Approved',
      InternshipStatus.rejected => 'Rejected',
      InternshipStatus.assigned => 'Assigned',
      InternshipStatus.active => 'Active',
      InternshipStatus.completed => 'Completed',
      InternshipStatus.archived => 'Archived',
    };
  }

  /// Parses a DDS Firestore value into an internship status.
  static InternshipStatus fromFirestore(String value) {
    return switch (value) {
      'draft' => InternshipStatus.draft,
      'pending_review' => InternshipStatus.pendingReview,
      'approved' => InternshipStatus.approved,
      'rejected' => InternshipStatus.rejected,
      'assigned' => InternshipStatus.assigned,
      'active' => InternshipStatus.active,
      'completed' => InternshipStatus.completed,
      'archived' => InternshipStatus.archived,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unknown internship status',
      ),
    };
  }
}
