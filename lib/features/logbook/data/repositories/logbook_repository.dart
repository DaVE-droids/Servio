import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/logbook_status.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../notifications/domain/notification_factory.dart';
import '../models/logbook_entry_model.dart';
import '../models/logbook_entry_request.dart';
import '../services/logbook_service.dart';

/// Repository for digital logbook operations.
class LogbookRepository {
  /// Creates a logbook repository.
  const LogbookRepository(this._service);

  final LogbookService _service;

  /// Creates today's entry, or resubmits it after changes were requested.
  /// Refuses to overwrite an already-approved entry (BR-LOG-003).
  Future<Result<LogbookEntryModel>> submitEntry(
    LogbookEntryRequest request,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final day = DateTime.utc(now.year, now.month, now.day);
      final documentId = _service.documentIdFor(
        internshipId: request.internshipId,
        day: day,
      );

      final existing = await _service.getEntry(documentId);
      final existingData = existing.data();
      if (existing.exists && existingData != null) {
        final existingStatus = LogbookStatusSerialization.fromFirestore(
          existingData['status'] as String,
        );
        if (existingStatus == LogbookStatus.approved) {
          return const Failure(
            AppFailure(
              message: 'This entry has already been approved and is read-only.',
              type: FailureType.validation,
              code: 'entry-locked',
            ),
          );
        }
      }

      final createdAt = existing.exists && existingData != null
          ? _readDateTime(existingData['createdAt'])
          : now;

      final entry = LogbookEntryModel(
        entryId: documentId,
        internshipId: request.internshipId,
        studentId: request.studentId,
        studentName: request.studentName,
        studentMatricNumber: request.studentMatricNumber,
        lecturerId: request.lecturerId,
        lecturerName: request.lecturerName,
        companyName: request.companyName,
        state: request.state,
        date: day,
        activities: request.activities,
        skillsLearned: request.skillsLearned,
        challenges: request.challenges,
        solutionsApplied: request.solutionsApplied,
        hoursWorked: request.hoursWorked,
        status: LogbookStatus.pending,
        createdAt: createdAt,
        updatedAt: now,
      );

      await _service.saveEntry(documentId: documentId, data: entry.toJson());
      return Success(entry);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Approves a pending entry, locking it.
  Future<Result<void>> approveEntry(LogbookEntryModel entry) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.updateEntry(
        documentId: entry.entryId,
        updates: {
          'status': LogbookStatus.approved.firestoreValue,
          'updatedAt': Timestamp.fromDate(now),
        },
        notifications: [
          NotificationFactory.logbookApproved(
            notificationId: _service.createNotificationId(),
            studentId: entry.studentId,
            entryId: entry.entryId,
            lecturerId: entry.lecturerId,
            lecturerName: entry.lecturerName,
            entryDate: entry.date,
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

  /// Requests changes on a pending entry, keeping it editable.
  Future<Result<void>> requestChanges({
    required LogbookEntryModel entry,
    required String comments,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _service.updateEntry(
        documentId: entry.entryId,
        updates: {
          'status': LogbookStatus.changesRequested.firestoreValue,
          'lecturerComments': comments,
          'updatedAt': Timestamp.fromDate(now),
        },
        notifications: [
          NotificationFactory.logbookChangesRequested(
            notificationId: _service.createNotificationId(),
            studentId: entry.studentId,
            entryId: entry.entryId,
            lecturerId: entry.lecturerId,
            lecturerName: entry.lecturerName,
            entryDate: entry.date,
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

  /// Retrieves today's entry for an internship, if any.
  Future<Result<LogbookEntryModel?>> getTodayEntry(String internshipId) async {
    try {
      final now = DateTime.now().toUtc();
      final day = DateTime.utc(now.year, now.month, now.day);
      final documentId = _service.documentIdFor(
        internshipId: internshipId,
        day: day,
      );

      final snapshot = await _service.getEntry(documentId);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return const Success(null);
      }
      return Success(LogbookEntryModel.fromJson(data));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves recent logbook entries for a student.
  Future<Result<List<LogbookEntryModel>>> getStudentEntries(
    String studentId,
  ) async {
    try {
      final snapshot = await _service.getStudentEntries(studentId);
      final entries = snapshot.docs
          .map((doc) => LogbookEntryModel.fromJson(doc.data()))
          .toList();
      return Success(entries);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Retrieves entries awaiting review across a lecturer's assigned
  /// students.
  Future<Result<List<LogbookEntryModel>>> getPendingReviews(
    String lecturerId,
  ) async {
    try {
      final snapshot = await _service.getPendingReviews(lecturerId);
      final entries = snapshot.docs
          .map((doc) => LogbookEntryModel.fromJson(doc.data()))
          .toList();
      return Success(entries);
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
      _ => 'Unable to save your logbook entry. Please try again.',
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

DateTime _readDateTime(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    String text => DateTime.parse(text).toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };
}
