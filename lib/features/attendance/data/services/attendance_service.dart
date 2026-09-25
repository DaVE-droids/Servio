import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for attendance documents.
class AttendanceService {
  /// Creates an attendance service.
  const AttendanceService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Builds the deterministic attendance document ID for a given
  /// internship and calendar day: `{internshipId}_{yyyy-MM-dd}`. Used (not
  /// an auto ID, deliberately) so check-in can be enforced atomically via a
  /// transaction — see docs/CHANGELOG.md.
  String documentIdFor({required String internshipId, required DateTime day}) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '${internshipId}_$y-$m-$d';
  }

  /// Creates a new audit event document ID.
  String createAuditEventId() {
    return _firestore.collection('audit_events').doc().id;
  }

  /// Records a check-in, failing if today's record already exists.
  ///
  /// Runs as a transaction: reads the deterministic doc for today, and
  /// only creates it if absent, preventing two concurrent check-ins from
  /// both succeeding (ARS §9). Throws [StateError] if already checked in.
  ///
  /// [auditEvent] is written inside that same transaction, so a duplicate
  /// check-in that rolls back leaves no audit record behind either. This
  /// is the one write path that uses a transaction rather than a batch —
  /// everything else audits through a batch.
  Future<void> checkIn({
    required String documentId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? auditEvent,
  }) {
    final docRef = _firestore.collection('attendance').doc(documentId);
    return _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        throw StateError('already-checked-in');
      }
      transaction.set(docRef, data);
      if (auditEvent != null) {
        transaction.set(
          _firestore
              .collection('audit_events')
              .doc(auditEvent['eventId'] as String),
          auditEvent,
        );
      }
    });
  }

  /// Records a check-out against today's existing attendance document.
  Future<void> checkOut({
    required String documentId,
    required Map<String, dynamic> updates,
    Map<String, dynamic>? auditEvent,
  }) {
    final docRef = _firestore.collection('attendance').doc(documentId);
    if (auditEvent == null) {
      return docRef.update(updates);
    }

    final batch = _firestore.batch();
    batch.update(docRef, updates);
    batch.set(
      _firestore
          .collection('audit_events')
          .doc(auditEvent['eventId'] as String),
      auditEvent,
    );
    return batch.commit();
  }

  /// Returns today's attendance document for an internship, if any.
  Future<DocumentSnapshot<Map<String, dynamic>>> getTodayAttendance(
    String documentId,
  ) {
    return _firestore.collection('attendance').doc(documentId).get();
  }

  /// Returns recent attendance history for a student.
  ///
  /// Filters on `studentId`, not `internshipId`, deliberately: the
  /// security rule's `get`/`list` check is keyed on `studentId`, and
  /// Firestore rejects a `list` query outright (permission-denied, not a
  /// partial result) if it can't statically prove every possible result
  /// satisfies the rule — which it can't do when the query's filter field
  /// doesn't match the rule's checked field. See docs/CHANGELOG.md.
  Future<QuerySnapshot<Map<String, dynamic>>> getAttendanceHistory(
    String studentId, {
    String? lecturerId,
  }) {
    // A lecturer may only list their own students' attendance, and
    // Firestore rejects a query it can't prove stays inside that — so when
    // a lecturer asks, the query is narrowed to their own records too.
    Query<Map<String, dynamic>> query = _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId);
    if (lecturerId != null) {
      query = query.where('lecturerId', isEqualTo: lecturerId);
    }
    return query.orderBy('date', descending: true).limit(30).get();
  }

  /// Returns recent attendance records across a lecturer's assigned
  /// students.
  Future<QuerySnapshot<Map<String, dynamic>>> getAttendanceForLecturer(
    String lecturerId,
  ) {
    return _firestore
        .collection('attendance')
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('date', descending: true)
        .limit(50)
        .get();
  }
}
