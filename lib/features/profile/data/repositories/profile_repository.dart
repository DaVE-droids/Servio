import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/domain/audit_event_factory.dart';
import '../../../notifications/domain/notification_factory.dart';
import '../models/profile_photo_upload_request.dart';
import '../models/profile_update_request.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

/// Repository for user profile read and update operations.
class ProfileRepository {
  /// Creates a profile repository.
  const ProfileRepository(this._profileService);

  final ProfileService _profileService;

  /// Loads the current user's profile document.
  Future<Result<UserModel>> getCurrentUser(String uid) async {
    try {
      if (uid.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message: 'Your session has expired. Please sign in again.',
            type: FailureType.authentication,
          ),
        );
      }

      final snapshot = await _profileService.getProfile(uid);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return const Failure(
          AppFailure(
            message:
                'Your profile could not be found. Please contact your coordinator.',
            type: FailureType.authorization,
          ),
        );
      }

      return Success(UserModel.fromJson(data));
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Saves permitted profile changes for the current user.
  Future<Result<UserModel>> updateCurrentUser({
    required String uid,
    required ProfileUpdateRequest request,
  }) async {
    try {
      if (uid.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message: 'Your session has expired. Please sign in again.',
            type: FailureType.authentication,
          ),
        );
      }

      final currentResult = await getCurrentUser(uid);
      switch (currentResult) {
        case Failure<UserModel>():
          return currentResult;
        case Success<UserModel>(:final data):
          final now = DateTime.now().toUtc();
          final updates = {
            ...request.toEditableJson(),
            'updatedAt': Timestamp.fromDate(now),
          };
          await _profileService.updateProfile(uid, updates);
          return Success(
            UserModel(
              uid: data.uid,
              firstName: request.firstName.trim(),
              lastName: request.lastName.trim(),
              email: data.email,
              role: data.role,
              department: data.department,
              isEmailVerified: data.isEmailVerified,
              isActive: data.isActive,
              createdAt: data.createdAt,
              updatedAt: now,
              phoneNumber: _nullableTrim(request.phoneNumber),
              faculty: _nullableTrim(request.faculty),
              matricNumber: data.matricNumber,
              staffId: data.staffId,
              profilePhotoUrl: _nullableTrim(request.profilePhotoUrl),
              institutionId: data.institutionId,
            ),
          );
      }
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Uploads a profile photo and saves the resulting URL on the profile.
  Future<Result<UserModel>> uploadProfilePhoto({
    required String uid,
    required ProfilePhotoUploadRequest request,
  }) async {
    try {
      if (uid.trim().isEmpty) {
        return const Failure(
          AppFailure(
            message: 'Your session has expired. Please sign in again.',
            type: FailureType.authentication,
          ),
        );
      }

      if (!request.contentType.startsWith('image/')) {
        return const Failure(
          AppFailure(
            message: 'Please select a valid image file.',
            type: FailureType.validation,
          ),
        );
      }

      final currentResult = await getCurrentUser(uid);
      switch (currentResult) {
        case Failure<UserModel>():
          return currentResult;
        case Success<UserModel>(:final data):
          final photoUrl = await _profileService.uploadProfilePhoto(
            uid: uid,
            bytes: request.bytes,
            contentType: request.contentType,
          );
          final now = DateTime.now().toUtc();
          await _profileService.updateProfile(uid, {
            'profilePhotoUrl': photoUrl,
            'updatedAt': Timestamp.fromDate(now),
          });
          return Success(
            UserModel(
              uid: data.uid,
              firstName: data.firstName,
              lastName: data.lastName,
              email: data.email,
              role: data.role,
              department: data.department,
              isEmailVerified: data.isEmailVerified,
              isActive: data.isActive,
              createdAt: data.createdAt,
              updatedAt: now,
              phoneNumber: data.phoneNumber,
              faculty: data.faculty,
              matricNumber: data.matricNumber,
              staffId: data.staffId,
              profilePhotoUrl: photoUrl,
              institutionId: data.institutionId,
            ),
          );
      }
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Returns all lecturers — approved and awaiting approval — sorted by
  /// name. Callers that assign students must use only active ones.
  Future<Result<List<UserModel>>> getLecturers() async {
    try {
      final snapshot = await _profileService.getLecturers();
      final lecturers =
          snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList()
            ..sort(_byName);
      return Success(lecturers);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Returns all students, sorted by name (coordinator only).
  Future<Result<List<UserModel>>> getStudents() async {
    try {
      final snapshot = await _profileService.getStudents();
      final students =
          snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList()
            ..sort(_byName);
      return Success(students);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Approves ([isActive] true) or deactivates a lecturer account. Approval
  /// also notifies the lecturer; both directions are audited.
  Future<Result<void>> setLecturerActive({
    required UserModel lecturer,
    required bool isActive,
    required String coordinatorId,
    required String coordinatorName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      await _profileService.setUserActive(
        uid: lecturer.uid,
        isActive: isActive,
        auditEvent: AuditEventFactory.lecturerAccessChanged(
          eventId: _profileService.newId('audit_events'),
          coordinatorId: coordinatorId,
          coordinatorName: coordinatorName,
          lecturerId: lecturer.uid,
          lecturerName: '${lecturer.firstName} ${lecturer.lastName}',
          isActive: isActive,
          createdAt: now,
        ).toJson(),
        notification: isActive
            ? NotificationFactory.lecturerAccountApproved(
                notificationId: _profileService.newId('notifications'),
                lecturerId: lecturer.uid,
                coordinatorId: coordinatorId,
                coordinatorName: coordinatorName,
                createdAt: now,
              ).toJson()
            : null,
      );
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  static int _byName(UserModel a, UserModel b) {
    final lastNameComparison = a.lastName.compareTo(b.lastName);
    return lastNameComparison != 0
        ? lastNameComparison
        : a.firstName.compareTo(b.firstName);
  }

  AppFailure _mapAuthException(FirebaseAuthException error) {
    return AppFailure(
      message: 'Your session could not be verified. Please sign in again.',
      type: FailureType.authentication,
      code: error.code,
      technicalDetails: error,
    );
  }

  AppFailure _mapFirebaseException(FirebaseException error) {
    final message = switch (error.code) {
      'permission-denied' =>
        'You do not have permission to update these profile details.',
      'unavailable' =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to load your profile. Please try again.',
    };
    return AppFailure(
      message: message,
      type: FailureType.database,
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

String? _nullableTrim(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
