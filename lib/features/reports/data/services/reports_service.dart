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
  Future<int> countAttendance(String internshipId) => _count(
    _firestore
        .collection('attendance')
        .where('internshipId', isEqualTo: internshipId),
  );

  /// Number of logbook entries for an internship.
  Future<int> countLogbookEntries(String internshipId) => _count(
    _firestore
        .collection('logbook_entries')
        .where('internshipId', isEqualTo: internshipId),
  );

  /// Number of approved logbook entries for an internship.
  Future<int> countApprovedLogbookEntries(String internshipId) => _count(
    _firestore
        .collection('logbook_entries')
        .where('internshipId', isEqualTo: internshipId)
        .where('status', isEqualTo: 'approved'),
  );

  /// Number of supervision visits recorded for an internship.
  Future<int> countVisits(String internshipId) => _count(
    _firestore
        .collection('supervision_reports')
        .where('internshipId', isEqualTo: internshipId),
  );

  /// All four progress counts for one internship.
  ///
  /// Students and lecturers may only count records that are theirs, and a
  /// Firestore query is only allowed if it can't return anything else — so
  /// they pass [studentId] or [lecturerId] and every query is narrowed to
  /// match the security rules. Coordinators pass neither.
  Future<List<int>> countProgress(
    String internshipId, {
    String? studentId,
    String? lecturerId,
  }) {
    Query<Map<String, dynamic>> scoped(String collection) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(collection)
          .where('internshipId', isEqualTo: internshipId);
      if (studentId != null) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      if (lecturerId != null) {
        query = query.where('lecturerId', isEqualTo: lecturerId);
      }
      return query;
    }

    return Future.wait([
      _count(scoped('attendance')),
      _count(scoped('logbook_entries')),
      _count(scoped('logbook_entries').where('status', isEqualTo: 'approved')),
      _count(scoped('supervision_reports')),
    ]);
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
