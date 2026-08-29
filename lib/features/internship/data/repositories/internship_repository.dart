import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/enums/internship_status.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
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
    required String department,
    required InternshipSubmissionRequest request,
    required double companyLatitude,
    required double companyLongitude,
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
        status: InternshipStatus.pendingReview,
        companyName: request.companyName.trim(),
        companyAddress: request.companyAddress.trim(),
        companyLatitude: companyLatitude,
        companyLongitude: companyLongitude,
        companySupervisorName: request.companySupervisorName.trim(),
        companySupervisorPhone: request.companySupervisorPhone.trim(),
        department: department.trim(),
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

  /// Approves a pending internship placement.
  Future<Result<void>> approveInternship({
    required String internshipId,
    required String coordinatorId,
  }) async {
    try {
      await _service.approveInternship(
        internshipId: internshipId,
        coordinatorId: coordinatorId,
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Rejects a pending internship placement.
  Future<Result<void>> rejectInternship({
    required String internshipId,
    required String coordinatorId,
  }) async {
    try {
      await _service.rejectInternship(
        internshipId: internshipId,
        coordinatorId: coordinatorId,
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

  /// Activates an internship, moving assigned -> active.
  Future<Result<void>> activateInternship(String internshipId) async {
    try {
      await _service.activateInternship(internshipId: internshipId);
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Assigns a lecturer to an approved internship.
  Future<Result<void>> assignLecturer({
    required String internshipId,
    required String lecturerId,
    required String lecturerName,
  }) async {
    try {
      await _service.assignLecturer(
        internshipId: internshipId,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }
}
