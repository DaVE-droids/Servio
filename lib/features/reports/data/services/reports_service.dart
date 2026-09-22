import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore counting queries behind coordinator reports.
///
/// Uses `count()` aggregations rather than downloading documents: Firestore
/// bills an aggregation at roughly one read per thousand matching entries,
/// so counting a student's 90 attendance records costs one read instead of
/// ninety. Every query filters on equality only, which Firestore serves
/// from its automatic single-field indexes — no composite index needed.
class ReportsService {
  /// Creates a reports service.
  const ReportsService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Number of attendance records for an internship.
  Future<int> countAttendance(String internshipId) =>
      _count(_firestore.collection('attendance')
          .where('internshipId', isEqualTo: internshipId));

  /// Number of logbook entries for an internship.
  Future<int> countLogbookEntries(String internshipId) =>
      _count(_firestore.collection('logbook_entries')
          .where('internshipId', isEqualTo: internshipId));

  /// Number of approved logbook entries for an internship.
  Future<int> countApprovedLogbookEntries(String internshipId) =>
      _count(_firestore.collection('logbook_entries')
          .where('internshipId', isEqualTo: internshipId)
          .where('status', isEqualTo: 'approved'));

  /// Number of supervision visits recorded for an internship.
  Future<int> countVisits(String internshipId) =>
      _count(_firestore.collection('supervision_reports')
          .where('internshipId', isEqualTo: internshipId));

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
