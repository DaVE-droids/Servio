/// Review states for digital logbook entries.
enum LogbookStatus {
  /// Entry is waiting for review.
  pending,

  /// Entry was approved by a lecturer.
  approved,

  /// Lecturer requested changes.
  changesRequested,
}
