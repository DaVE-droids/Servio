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

  /// Creates a new internship placement document.
  Future<void> createInternship({
    required String internshipId,
    required Map<String, dynamic> data,
  }) {
    return _firestore.collection('internships').doc(internshipId).set(data);
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

  /// Approves an internship placement.
  Future<void> approveInternship({
    required String internshipId,
    required String coordinatorId,
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _firestore.collection('internships').doc(internshipId).update({
      'status': 'approved',
      'coordinatorId': coordinatorId,
      'approvedAt': now,
      'updatedAt': now,
    });
  }

  /// Rejects an internship placement.
  Future<void> rejectInternship({
    required String internshipId,
    required String coordinatorId,
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _firestore.collection('internships').doc(internshipId).update({
      'status': 'rejected',
      'coordinatorId': coordinatorId,
      'rejectedAt': now,
      'updatedAt': now,
    });
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
  Future<void> activateInternship({required String internshipId}) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _firestore.collection('internships').doc(internshipId).update({
      'status': 'active',
      'activatedAt': now,
      'updatedAt': now,
    });
  }

  /// Assigns a lecturer to an approved internship.
  Future<void> assignLecturer({
    required String internshipId,
    required String lecturerId,
    required String lecturerName,
  }) {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return _firestore.collection('internships').doc(internshipId).update({
      'status': 'assigned',
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'assignedAt': now,
      'updatedAt': now,
    });
  }
}
