import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for supervision report documents.
class SupervisionService {
  /// Creates a supervision service.
  const SupervisionService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Creates a new supervision report document ID.
  String createReportId() {
    return _firestore.collection('supervision_reports').doc().id;
  }

  /// Creates a new audit event document ID.
  String createAuditEventId() {
    return _firestore.collection('audit_events').doc().id;
  }

  /// Writes the supervision report and its audit event atomically, per
  /// ARS §9 (Create Supervision Report is a batched write, not a
  /// transaction — the two documents are independent, and there's no prior
  /// read needed to decide whether to write).
  Future<void> createReport({
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> auditEventData,
    List<Map<String, dynamic>> notifications = const [],
  }) {
    final reportId = reportData['reportId'] as String;
    final auditEventId = auditEventData['eventId'] as String;

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('supervision_reports').doc(reportId),
      reportData,
    );
    batch.set(
      _firestore.collection('audit_events').doc(auditEventId),
      auditEventData,
    );
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

  /// Returns every report this lecturer has submitted, most recent visit
  /// first.
  ///
  /// Deliberately filtered by `lecturerId` — the exact field the
  /// `supervision_reports` list rule authorizes on. Filtering by
  /// `internshipId` instead (the more obvious "reports for this student"
  /// query) makes the query unprovable against that rule and Firestore
  /// denies it outright. Callers that want one internship's history filter
  /// this result client-side, which also means one query serves both the
  /// assigned-students list and each student's detail screen.
  Future<QuerySnapshot<Map<String, dynamic>>> getReports(String lecturerId) {
    return _firestore
        .collection('supervision_reports')
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('visitDate', descending: true)
        .get();
  }
}
