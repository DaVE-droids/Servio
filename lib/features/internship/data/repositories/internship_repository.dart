import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/enums/internship_status.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/domain/audit_event_factory.dart';
import '../../../notifications/domain/notification_factory.dart';
import '../models/internship_model.dart';
import '../models/internship_submission_request.dart';
import '../services/internship_service.dart';

/// Repository for student internship placement lifecycle operations.
class InternshipRepository {
  /// Creates an internship repository.
  const InternshipRepository(this._service);

  final InternshipService _service;

  /// Retrieves the current non-archived internship for a student.
  Future<Result<InternshipModel?>> getCurrentInternship(
    String studentId,
  ) async {
    try {
      if (studentId.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message: 'Your session has expired. Please sign in again.',
            type: FailureType.authentication,
          ),
        );
      }

      final snapshot = await _service.getCurrentInternship(studentId);
      if (snapshot.docs.isEmpty) {
        return const Success(null);
      }
      return Success(InternshipModel.fromJson(snapshot.docs.first.data()));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Submits a new student internship placement.
  Future<Result<InternshipModel>> submitInternship({
    required String studentId,
    required String studentName,
    required String studentMatricNumber,
    required String department,
    required InternshipSubmissionRequest request,
  }) async {
    try {
      if (studentId.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message: 'Your session has expired. Please sign in again.',
            type: FailureType.authentication,
          ),
        );
      }
      if (department.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message:
                'Your profile is missing a department. Please update your profile before submitting a placement.',
            type: FailureType.validation,
          ),
        );
      }

      final currentResult = await getCurrentInternship(studentId);
      switch (currentResult) {
        case Failure<InternshipModel?>():
          return Failure(currentResult.error);
        case Success<InternshipModel?>(:final data):
          if (data != null) {
            return const Failure(
              AppFailure(
                message: 'You already have an internship placement on record.',
                type: FailureType.validation,
                code: 'duplicate-internship',
              ),
            );
          }
      }

      final internshipId = _service.createInternshipId();
      final now = DateTime.now().toUtc();
      final internship = InternshipModel(
        internshipId: internshipId,
        studentId: studentId,
        studentName: studentName.trim(),
        studentMatricNumber: studentMatricNumber.trim(),
        status: InternshipStatus.pendingReview,
        companyName: request.companyName.trim(),
        companyAddress: request.companyAddress.trim(),
        companyLatitude: request.companyLatitude,
        companyLongitude: request.companyLongitude,
        companySupervisorName: request.companySupervisorName.trim(),
        companySupervisorPhone: request.companySupervisorPhone.trim(),
        department: department.trim(),
        country: request.country.trim(),
        state: request.state.trim(),
        startDate: request.startDate.toUtc(),
        endDate: request.endDate.toUtc(),
        submittedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await _service.createInternship(
        internshipId: internshipId,
        data: internship.toJson(),
        auditEvent: AuditEventFactory.placementSubmitted(
          eventId: _service.createAuditEventId(),
          studentId: studentId,
          studentName: studentName.trim(),
          internshipId: internshipId,
          companyName: internship.companyName,
          createdAt: now,
        ).toJson(),
      );
      return Success(internship);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  AppFailure _mapFirebaseException(FirebaseException error) {
    final message = switch (error.code) {
      'permission-denied' =>
        'You do not have permission to perform this action.',
      'unavailable' =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to save your internship placement. Please try again.',
    };
    return AppFailure(
      message: message,
      type: error.code == 'unavailable'
          ? FailureType.network
          : FailureType.database,
      code: error.code,
      technicalDetails: error,
    );
  }

  AppFailure _unknownFailure(Object error) {
    return AppFailure(
      message: 'Something unexpected happened. Please try again.',
      technicalDetails: error,
    );
  }

  /// Retrieves all internships awaiting coordinator review.
  Future<Result<List<InternshipModel>>> getPendingInternships() async {
    try {
      final snapshot = await _service.getPendingInternships();
      final internships = snapshot.docs
          .map((doc) => InternshipModel.fromJson(doc.data()))
          .toList();
      return Success(internships);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Approves a pending internship placement and notifies the student.
  Future<Result<void>> approveInternship({
    required InternshipModel internship,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.approveInternship(
        internshipId: internship.internshipId,
        coordinatorId: coordinatorId,
        notifications: [
          NotificationFactory.placementApproved(
            notificationId: _service.createNotificationId(),
            studentId: internship.studentId,
            internshipId: internship.internshipId,
            companyName: internship.companyName,
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            createdAt: now,
          ).toJson(),
        ],
        auditEvents: [
          AuditEventFactory.placementApproved(
            eventId: _service.createAuditEventId(),
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            internshipId: internship.internshipId,
            studentId: internship.studentId,
            studentName: _displayName(internship.studentName),
            companyName: internship.companyName,
            createdAt: now,
          ).toJson(),
        ],
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Rejects a pending internship placement and notifies the student.
  Future<Result<void>> rejectInternship({
    required InternshipModel internship,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.rejectInternship(
        internshipId: internship.internshipId,
        coordinatorId: coordinatorId,
        notifications: [
          NotificationFactory.placementRejected(
            notificationId: _service.createNotificationId(),
            studentId: internship.studentId,
            internshipId: internship.internshipId,
            companyName: internship.companyName,
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            createdAt: now,
          ).toJson(),
        ],
        auditEvents: [
          AuditEventFactory.placementRejected(
            eventId: _service.createAuditEventId(),
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            internshipId: internship.internshipId,
            studentId: internship.studentId,
            studentName: _displayName(internship.studentName),
            companyName: internship.companyName,
            createdAt: now,
          ).toJson(),
        ],
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves approved internships awaiting a lecturer assignment.
  Future<Result<List<InternshipModel>>> getApprovedInternships() async {
    try {
      final snapshot = await _service.getApprovedInternships();
      final internships = snapshot.docs
          .map((doc) => InternshipModel.fromJson(doc.data()))
          .toList();
      return Success(internships);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves internships currently assigned to a lecturer, sorted by
  /// company name.
  Future<Result<List<InternshipModel>>> getAssignedInternships(
    String lecturerId,
  ) async {
    try {
      final snapshot = await _service.getAssignedInternships(lecturerId);
      final internships = snapshot.docs
          .map((doc) => InternshipModel.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => a.companyName.compareTo(b.companyName));
      return Success(internships);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves internships assigned a lecturer but not yet activated.
  Future<Result<List<InternshipModel>>> getReadyToStartInternships() async {
    try {
      final snapshot = await _service.getReadyToStartInternships();
      final internships = snapshot.docs
          .map((doc) => InternshipModel.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => (a.assignedAt ?? a.updatedAt).compareTo(
          b.assignedAt ?? b.updatedAt,
        ));
      return Success(internships);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Activates an internship, moving assigned -> active, and records who
  /// started it.
  Future<Result<void>> activateInternship({
    required InternshipModel internship,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      await _service.activateInternship(
        internshipId: internship.internshipId,
        auditEvents: [
          AuditEventFactory.internshipActivated(
            eventId: _service.createAuditEventId(),
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            internshipId: internship.internshipId,
            studentId: internship.studentId,
            studentName: _displayName(internship.studentName),
            createdAt: DateTime.now().toUtc(),
          ).toJson(),
        ],
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Assigns a lecturer to an approved internship, notifying both the
  /// student and the newly assigned lecturer.
  Future<Result<void>> assignLecturer({
    required InternshipModel internship,
    required String lecturerId,
    required String lecturerName,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.assignLecturer(
        internshipId: internship.internshipId,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        notifications: [
          NotificationFactory.lecturerAssignedToStudent(
            notificationId: _service.createNotificationId(),
            studentId: internship.studentId,
            internshipId: internship.internshipId,
            lecturerName: lecturerName,
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            createdAt: now,
          ).toJson(),
          NotificationFactory.studentAssignedToLecturer(
            notificationId: _service.createNotificationId(),
            lecturerId: lecturerId,
            internshipId: internship.internshipId,
            studentName: internship.studentName.isEmpty
                ? 'a student'
                : internship.studentName,
            companyName: internship.companyName,
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            createdAt: now,
          ).toJson(),
        ],
        auditEvents: [
          AuditEventFactory.lecturerAssigned(
            eventId: _service.createAuditEventId(),
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            internshipId: internship.internshipId,
            studentId: internship.studentId,
            studentName: _displayName(internship.studentName),
            lecturerName: lecturerName,
            createdAt: now,
          ).toJson(),
        ],
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Marks an active internship completed, notifying the student and
  /// recording the audit event in the same batch.
  Future<Result<void>> completeInternship({
    required InternshipModel internship,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.completeInternship(
        internshipId: internship.internshipId,
        notifications: [
          NotificationFactory.internshipCompleted(
            notificationId: _service.createNotificationId(),
            studentId: internship.studentId,
            internshipId: internship.internshipId,
            companyName: internship.companyName,
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            createdAt: now,
          ).toJson(),
        ],
        auditEvents: [
          AuditEventFactory.internshipCompleted(
            eventId: _service.createAuditEventId(),
            coordinatorId: coordinatorId,
            coordinatorName: coordinatorName,
            internshipId: internship.internshipId,
            studentId: internship.studentId,
            studentName: _displayName(internship.studentName),
            createdAt: now,
          ).toJson(),
        ],
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves every internship on record (coordinator only).
  Future<Result<List<InternshipModel>>> getAllInternships() async {
    try {
      final snapshot = await _service.getAllInternships();
      final internships = snapshot.docs
          .map((doc) => InternshipModel.fromJson(doc.data()))
          .toList();
      return Success(internships);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Falls back to a neutral label when a placement predates the
  /// denormalized student name, so an audit line never reads "'s
  /// placement" with nothing in front of it.
  String _displayName(String studentName) =>
      studentName.trim().isEmpty ? 'a student' : studentName.trim();
}
