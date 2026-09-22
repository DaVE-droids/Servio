import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/domain/audit_event_factory.dart';
import '../../../notifications/domain/notification_factory.dart';
import '../models/supervision_report_model.dart';
import '../models/supervision_report_request.dart';
import '../services/supervision_service.dart';

/// Repository for lecturer supervision visit operations.
class SupervisionRepository {
  /// Creates a supervision repository.
  const SupervisionRepository(this._service);

  final SupervisionService _service;

  /// Creates a supervision report and its corresponding audit event
  /// (FR-SUP-006) in a single batched write.
  Future<Result<SupervisionReportModel>> createReport({
    required String lecturerId,
    required String lecturerName,
    required String studentId,
    required String studentName,
    required String studentMatricNumber,
    required String companyName,
    required String state,
    required SupervisionReportRequest request,
  }) async {
    try {
      final reportId = _service.createReportId();
      final auditEventId = _service.createAuditEventId();
      final now = DateTime.now().toUtc();

      final report = SupervisionReportModel(
        reportId: reportId,
        internshipId: request.internshipId,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        studentId: studentId,
        studentName: studentName,
        studentMatricNumber: studentMatricNumber,
        companyName: companyName,
        state: state,
        visitDate: request.visitDate.toUtc(),
        studentPresent: request.studentPresent,
        companyRepresentativePresent: request.companyRepresentativePresent,
        observation: request.observation.trim(),
        recommendations: request.recommendations.trim(),
        rating: request.rating,
        photoUrls: const [],
        createdAt: now,
      );

      final auditEvent = AuditEventFactory.supervisionReportCreated(
        eventId: auditEventId,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        reportId: reportId,
        studentId: studentId,
        studentName: studentName,
        createdAt: now,
      );

      await _service.createReport(
        reportData: report.toJson(),
        auditEventData: auditEvent.toJson(),
        notifications: [
          NotificationFactory.supervisionReportSubmitted(
            notificationId: _service.createNotificationId(),
            studentId: studentId,
            reportId: reportId,
            lecturerId: lecturerId,
            lecturerName: lecturerName,
            visitDate: request.visitDate,
            createdAt: now,
          ).toJson(),
        ],
      );
      return Success(report);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves every visit report this lecturer has submitted, most recent
  /// first. Per-internship history is filtered from this client-side — see
  /// [SupervisionService.getReports] for why the query is scoped by
  /// lecturer rather than by internship.
  Future<Result<List<SupervisionReportModel>>> getReports(
    String lecturerId,
  ) async {
    try {
      final snapshot = await _service.getReports(lecturerId);
      final reports = snapshot.docs
          .map((doc) => SupervisionReportModel.fromJson(doc.data()))
          .toList();
      return Success(reports);
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
      _ => 'Unable to save this visit report. Please try again.',
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
