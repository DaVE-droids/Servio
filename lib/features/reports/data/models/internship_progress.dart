/// How far along one internship is — the numbers a coordinator needs to
/// judge whether a student is on track.
class InternshipProgress {
  /// Creates an internship progress summary.
  const InternshipProgress({
    required this.attendanceDays,
    required this.logbookEntries,
    required this.logbookApproved,
    required this.visits,
  });

  /// No activity recorded yet.
  static const empty = InternshipProgress(
    attendanceDays: 0,
    logbookEntries: 0,
    logbookApproved: 0,
    visits: 0,
  );

  /// Days with an attendance check-in.
  final int attendanceDays;

  /// Logbook entries submitted (any status).
  final int logbookEntries;

  /// Logbook entries a lecturer has approved.
  final int logbookApproved;

  /// Supervision visits recorded by the lecturer.
  final int visits;
}
