import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for internship placement documents.
class InternshipService {
  /// Creates an internship service.
  const InternshipService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Returns the current non-archived internship for a student, if one exists.
  Future<QuerySnapshot<Map<String, dynamic>>> getCurrentInternship(
    String studentId,
  ) {
    return _firestore
        .collection('internships')
        .where('studentId', isEqualTo: studentId)
        .where(
          'status',
          whereIn: [
            'draft',
            'pending_review',
            'approved',
            'assigned',
            'active',
            'completed',
          ],
        )
        .limit(1)
        .get();
  }

  /// Creates a new internship placement document, together with the audit
  /// event recording the submission (FR-AUDIT-001).
  Future<void> createInternship({
    required String internshipId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? auditEvent,
  }) {
    final internshipRef = _firestore.collection('internships').doc(internshipId);
    if (auditEvent == null) {
      return internshipRef.set(data);
    }

    final batch = _firestore.batch();
    batch.set(internshipRef, data);
    batch.set(
      _firestore
          .collection('audit_events')
          .doc(auditEvent['eventId'] as String),
      auditEvent,
    );
    return batch.commit();
  }

  /// Creates a new internship document ID.
  String createInternshipId() {
    return _firestore.collection('internships').doc().id;
  }

  /// Returns internships awaiting coordinator review.
  Future<QuerySnapshot<Map<String, dynamic>>> getPendingInternships() {
    return _firestore
        .collection('internships')
        .where('status', isEqualTo: 'pending_review')
        .orderBy('submittedAt', descending: false)
        .get();
  }

  /// Creates a new notification document ID.
  String createNotificationId() {
    return _firestore.collection('notifications').doc().id;
  }

  /// Creates a new audit event document ID.
  String createAuditEventId() {
    return _firestore.collection('audit_events').doc().id;
  }

  /// Applies a status change and writes any accompanying notifications and
  /// audit events in one batch, so neither a student notification nor an
  /// audit record can describe a transition that didn't commit. Each
  /// document must carry its own ID field.
  Future<void> _updateWithSideEffects({
    required String internshipId,
    required Map<String, dynamic> updates,
    required List<Map<String, dynamic>> notifications,
    required List<Map<String, dynamic>> auditEvents,
  }) {
    final internshipRef = _firestore
        .collection('internships')
        .doc(internshipId);
    if (notifications.isEmpty && auditEvents.isEmpty) {
      return internshipRef.update(updates);
    }

    final batch = _firestore.batch();
    batch.update(internshipRef, updates);
    for (final notification in notifications) {
      batch.set(
        _firestore
            .collection('notifications')
            .doc(notification['notificationId'] as String),
        notification,
      );
    }
    for (final auditEvent in auditEvents) {
      batch.set(
        _firestore
            .collection('audit_events')
            .doc(auditEvent['eventId'] as String),
        auditEvent,
      );
    }
    return batch.commit();
  }

  /// Approves an internship placement.
  Future<void> approveInternship({
    required String internshipId,
    required String coordinatorId,
    List<Map<String, dynamic>> notifications = const [],
    List<Map<String, dynamic>> auditEvents = const [],
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _updateWithSideEffects(
      internshipId: internshipId,
      updates: {
        'status': 'approved',
        'coordinatorId': coordinatorId,
        'approvedAt': now,
        'updatedAt': now,
      },
      notifications: notifications,
      auditEvents: auditEvents,
    );
  }

  /// Rejects an internship placement.
  Future<void> rejectInternship({
    required String internshipId,
    required String coordinatorId,
    List<Map<String, dynamic>> notifications = const [],
    List<Map<String, dynamic>> auditEvents = const [],
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _updateWithSideEffects(
      internshipId: internshipId,
      updates: {
        'status': 'rejected',
        'coordinatorId': coordinatorId,
        'rejectedAt': now,
        'updatedAt': now,
      },
      notifications: notifications,
      auditEvents: auditEvents,
    );
  }

  /// Returns approved internships that do not yet have a lecturer assigned.
  Future<QuerySnapshot<Map<String, dynamic>>> getApprovedInternships() {
    return _firestore
        .collection('internships')
        .where('status', isEqualTo: 'approved')
        .orderBy('approvedAt', descending: false)
        .get();
  }

  /// Returns internships currently assigned to a lecturer.
  Future<QuerySnapshot<Map<String, dynamic>>> getAssignedInternships(
    String lecturerId,
  ) {
    return _firestore
        .collection('internships')
        .where('lecturerId', isEqualTo: lecturerId)
        .get();
  }

  /// Returns internships assigned a lecturer but not yet activated.
  Future<QuerySnapshot<Map<String, dynamic>>> getReadyToStartInternships() {
    return _firestore
        .collection('internships')
        .where('status', isEqualTo: 'assigned')
        .get();
  }

  /// Activates an internship, moving assigned -> active.
  Future<void> activateInternship({
    required String internshipId,
    List<Map<String, dynamic>> auditEvents = const [],
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _updateWithSideEffects(
      internshipId: internshipId,
      updates: {'status': 'active', 'activatedAt': now, 'updatedAt': now},
      notifications: const [],
      auditEvents: auditEvents,
    );
  }

  /// Completes an internship, moving active -> completed. This is the last
  /// step of the placement cycle (DDS §10.2); attendance and logbook
  /// writes stop being accepted once the status leaves `active`.
  Future<void> completeInternship({
    required String internshipId,
    List<Map<String, dynamic>> notifications = const [],
    List<Map<String, dynamic>> auditEvents = const [],
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _updateWithSideEffects(
      internshipId: internshipId,
      updates: {'status': 'completed', 'completedAt': now, 'updatedAt': now},
      notifications: notifications,
      auditEvents: auditEvents,
    );
  }

  /// Returns every internship, for coordinator oversight screens (student
  /// management, lecturer workload, reports).
  ///
  /// Unfiltered on purpose: the `internships` list rule grants coordinators
  /// every document, and at pilot scale one read of the whole collection is
  /// simpler and cheaper than a query per screen. Revisit with pagination
  /// if the collection grows into the thousands.
  Future<QuerySnapshot<Map<String, dynamic>>> getAllInternships() {
    return _firestore.collection('internships').get();
  }

  /// Assigns a lecturer to an approved internship.
  Future<void> assignLecturer({
    required String internshipId,
    required String lecturerId,
    required String lecturerName,
    List<Map<String, dynamic>> notifications = const [],
    List<Map<String, dynamic>> auditEvents = const [],
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _updateWithSideEffects(
      internshipId: internshipId,
      updates: {
        'status': 'assigned',
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'assignedAt': now,
        'updatedAt': now,
      },
      notifications: notifications,
      auditEvents: auditEvents,
    );
  }
}
