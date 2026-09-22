import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/domain/audit_event_factory.dart';
import '../models/attendance_check_in_request.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

/// Repository for daily attendance operations.
class AttendanceRepository {
  /// Creates an attendance repository.
  const AttendanceRepository(this._service);

  final AttendanceService _service;

  /// Records a check-in for today, failing if already checked in or the
  /// student already has a record for today.
  Future<Result<AttendanceModel>> checkIn(
    AttendanceCheckInRequest request,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final day = DateTime.utc(now.year, now.month, now.day);
      final documentId = _service.documentIdFor(
        internshipId: request.internshipId,
        day: day,
      );

      final attendance = AttendanceModel(
        attendanceId: documentId,
        internshipId: request.internshipId,
        studentId: request.studentId,
        studentName: request.studentName,
        studentMatricNumber: request.studentMatricNumber,
        lecturerId: request.lecturerId,
        lecturerName: request.lecturerName,
        companyName: request.companyName,
        state: request.state,
        date: day,
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
        createdAt: now,
        updatedAt: now,
      );

      await _service.checkIn(
        documentId: documentId,
        data: attendance.toJson(),
        auditEvent: AuditEventFactory.attendanceCheckedIn(
          eventId: _service.createAuditEventId(),
          studentId: request.studentId,
          studentName: request.studentName,
          attendanceId: documentId,
          createdAt: now,
        ).toJson(),
      );
      return Success(attendance);
    } on StateError {
      return const Failure(
        AppFailure(
          message: 'You have already checked in today.',
          type: FailureType.validation,
          code: 'already-checked-in',
        ),
      );
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Records a check-out against today's attendance record.
  Future<Result<void>> checkOut({
    required String internshipId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final day = DateTime.utc(now.year, now.month, now.day);
      final documentId = _service.documentIdFor(
        internshipId: internshipId,
        day: day,
      );

      await _service.checkOut(
        documentId: documentId,
        updates: {
          'checkOutTime': Timestamp.fromDate(now),
          'status': AttendanceStatus.completed.firestoreValue,
          'updatedAt': Timestamp.fromDate(now),
        },
        auditEvent: AuditEventFactory.attendanceCheckedOut(
          eventId: _service.createAuditEventId(),
          studentId: studentId,
          studentName: studentName,
          attendanceId: documentId,
          createdAt: now,
        ).toJson(),
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves today's attendance for an internship, if any.
  Future<Result<AttendanceModel?>> getTodayAttendance(
    String internshipId,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final day = DateTime.utc(now.year, now.month, now.day);
      final documentId = _service.documentIdFor(
        internshipId: internshipId,
        day: day,
      );

      final snapshot = await _service.getTodayAttendance(documentId);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return const Success(null);
      }
      return Success(AttendanceModel.fromJson(data));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves recent attendance history for a student.
  Future<Result<List<AttendanceModel>>> getAttendanceHistory(
    String studentId,
  ) async {
    try {
      final snapshot = await _service.getAttendanceHistory(studentId);
      final records = snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data()))
          .toList();
      return Success(records);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves recent attendance records across a lecturer's assigned
  /// students.
  Future<Result<List<AttendanceModel>>> getAttendanceForLecturer(
    String lecturerId,
  ) async {
    try {
      final snapshot = await _service.getAttendanceForLecturer(lecturerId);
      final records = snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data()))
          .toList();
      return Success(records);
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
      _ => 'Unable to save your attendance. Please try again.',
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
}
