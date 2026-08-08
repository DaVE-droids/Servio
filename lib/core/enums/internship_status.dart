/// Lifecycle states for internship placement records.
enum InternshipStatus {
  /// Placement is being prepared.
  draft,

  /// Placement has been submitted for review.
  pendingReview,

  /// Placement has been approved.
  approved,

  /// Lecturer has been assigned.
  assigned,

  /// Internship is active.
  active,

  /// Internship has been completed.
  completed,

  /// Internship has been archived.
  archived,
}
