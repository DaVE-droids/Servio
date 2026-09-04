import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for logbook entry documents.
class LogbookService {
  /// Creates a logbook service.
  const LogbookService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Builds the deterministic logbook entry document ID for a given
  /// internship and calendar day: `{internshipId}_{yyyy-MM-dd}`. Same
  /// reasoning as attendance's deterministic ID — see docs/CHANGELOG.md.
  String documentIdFor({required String internshipId, required DateTime day}) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '${internshipId}_$y-$m-$d';
  }

  /// Creates or overwrites today's logbook entry.
  Future<void> saveEntry({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return _firestore.collection('logbook_entries').doc(documentId).set(data);
  }

  /// Updates specific fields on an existing entry (lecturer review, or a
  /// student resubmission after changes were requested).
  ///
  /// [notifications] are written in the same batch, so a student can never
  /// be told their entry was reviewed unless the review itself committed.
  /// Each entry must carry its own `notificationId`.
  Future<void> updateEntry({
    required String documentId,
    required Map<String, dynamic> updates,
    List<Map<String, dynamic>> notifications = const [],
  }) {
    final entryRef = _firestore.collection('logbook_entries').doc(documentId);
    if (notifications.isEmpty) {
      return entryRef.update(updates);
    }

    final batch = _firestore.batch();
    batch.update(entryRef, updates);
    for (final notification in notifications) {
      batch.set(
        _firestore
            .collection('notifications')
            .doc(notification['notificationId'] as String),
        notification,
      );
    }
    return batch.commit();
  }

  /// Creates a new notification document ID.
  String createNotificationId() {
    return _firestore.collection('notifications').doc().id;
  }

  /// Returns a specific entry by ID, if it exists.
  Future<DocumentSnapshot<Map<String, dynamic>>> getEntry(String documentId) {
    return _firestore.collection('logbook_entries').doc(documentId).get();
  }

  /// Returns recent logbook entries for a student.
  ///
  /// Filters on `studentId` to match what the security rule checks — see
  /// the attendance `getAttendanceHistory()` comment for why this matters
  /// (Firestore rejects/silently-empties a `list` query it can't
  /// statically prove safe against the rule's checked field).
  Future<QuerySnapshot<Map<String, dynamic>>> getStudentEntries(
    String studentId,
  ) {
    return _firestore
        .collection('logbook_entries')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .limit(30)
        .get();
  }

  /// Returns entries awaiting review across a lecturer's assigned
  /// students.
  Future<QuerySnapshot<Map<String, dynamic>>> getPendingReviews(
    String lecturerId,
  ) {
    return _firestore
        .collection('logbook_entries')
        .where('lecturerId', isEqualTo: lecturerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .get();
  }
}
