import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/domain/audit_event_factory.dart';
import '../../../profile/data/models/user_model.dart';
import '../models/auth_requests.dart';
import '../models/auth_session.dart';
import '../services/authentication_service.dart';

/// Repository for authentication and account lifecycle operations.
class AuthenticationRepository {
  /// Creates an authentication repository.
  const AuthenticationRepository(this._authenticationService, this._firestore);

  final AuthenticationService _authenticationService;
  final FirebaseFirestore _firestore;

  /// Emits app sessions by combining Firebase Auth state with Firestore roles.
  Stream<AuthSession> authSessionChanges() async* {
    await for (final firebaseUser
        in _authenticationService.authStateChanges()) {
      if (firebaseUser == null) {
        yield const AuthSession(firebaseUser: null, isEmailVerified: false);
        continue;
      }

      final access = await _loadAccess(firebaseUser.uid);
      yield AuthSession(
        firebaseUser: firebaseUser,
        isEmailVerified: firebaseUser.emailVerified,
        role: access.role,
        isActive: access.isActive,
      );
    }
  }

  /// Returns the current resolved app session.
  Future<AuthSession> currentSession() async {
    final firebaseUser = _authenticationService.currentUser;
    if (firebaseUser == null) {
      return const AuthSession(firebaseUser: null, isEmailVerified: false);
    }

    final access = await _loadAccess(firebaseUser.uid);
    return AuthSession(
      firebaseUser: firebaseUser,
      isEmailVerified: firebaseUser.emailVerified,
      role: access.role,
      isActive: access.isActive,
    );
  }

  /// Registers a student or lecturer account and creates the Firestore
  /// profile.
  ///
  /// Lecturers are created inactive: they can sign in, but have no lecturer
  /// permissions until a coordinator approves them (the security rules
  /// enforce this, not just the UI).
  Future<Result<UserModel>> register(RegisterRequest request) async {
    try {
      final credential = await _authenticationService.register(
        email: request.email.trim(),
        password: request.password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Failure(
          AppFailure(
            message: 'Unable to create your account. Please try again.',
          ),
        );
      }

      final isLecturer = request.role == UserRole.lecturer;
      final now = DateTime.now().toUtc();
      final user = UserModel(
        uid: firebaseUser.uid,
        firstName: request.firstName.trim(),
        lastName: request.lastName.trim(),
        email: request.email.trim(),
        phoneNumber: request.phoneNumber?.trim(),
        role: isLecturer ? UserRole.lecturer : UserRole.student,
        department: request.department.trim(),
        faculty: request.faculty?.trim(),
        matricNumber: isLecturer ? null : request.idNumber.trim(),
        staffId: isLecturer ? request.idNumber.trim() : null,
        isEmailVerified: firebaseUser.emailVerified,
        isActive: !isLecturer,
        createdAt: now,
        updatedAt: now,
      );

      // Profile and "account created" audit record in one batch, so the
      // audit trail can't record a signup whose profile never saved.
      final auditEventRef = _firestore.collection('audit_events').doc();
      final auditEvent = AuditEventFactory.accountCreated(
        eventId: auditEventRef.id,
        userId: firebaseUser.uid,
        userName: '${user.firstName} ${user.lastName}',
        role: user.role.name,
        createdAt: now,
      );

      try {
        final batch = _firestore.batch();
        batch.set(
          _firestore.collection('users').doc(firebaseUser.uid),
          user.toJson(),
        );
        batch.set(auditEventRef, auditEvent.toJson());
        await batch.commit();
      } on FirebaseException catch (error) {
        await firebaseUser.delete();
        return Failure(_mapFirebaseException(error));
      }
      await firebaseUser.sendEmailVerification();
      return Success(user);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Logs in an existing email/password account.
  Future<Result<UserModel>> login(LoginRequest request) async {
    try {
      final credential = await _authenticationService.login(
        email: request.email.trim(),
        password: request.password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Failure(
          AppFailure(message: 'Unable to sign you in. Please try again.'),
        );
      }

      final userResult = await _loadUser(firebaseUser.uid);
      return userResult;
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Sends a password reset email.
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _authenticationService.sendPasswordResetEmail(email.trim());
      return const Success(null);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Sends an email verification message to the current user.
  Future<Result<void>> sendVerificationEmail() async {
    try {
      await _authenticationService.sendEmailVerification();
      return const Success(null);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Reloads Firebase user state and updates the cached verification field.
  Future<Result<AuthSession>> reloadCurrentUser() async {
    try {
      final firebaseUser = await _authenticationService.reloadCurrentUser();
      if (firebaseUser == null) {
        return const Success(
          AuthSession(firebaseUser: null, isEmailVerified: false),
        );
      }

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'isEmailVerified': firebaseUser.emailVerified,
        'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
      });

      final access = await _loadAccess(firebaseUser.uid);
      return Success(
        AuthSession(
          firebaseUser: firebaseUser,
          isEmailVerified: firebaseUser.emailVerified,
          role: access.role,
          isActive: access.isActive,
        ),
      );
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Logs out the current user.
  Future<Result<void>> logout() async {
    try {
      await _authenticationService.logout();
      return const Success(null);
    } on FirebaseAuthException catch (error) {
      return Failure(_mapAuthException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  Future<Result<UserModel>> _loadUser(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return const Failure(
          AppFailure(
            message:
                'Your account profile could not be found. Please contact your coordinator.',
            type: FailureType.authorization,
          ),
        );
      }
      return Success(UserModel.fromJson(data));
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Loads the role and active flag from `users/{uid}` in one read. The
  /// router needs both: role picks the dashboard, and `isActive` holds a
  /// not-yet-approved lecturer on the "awaiting approval" screen.
  Future<({UserRole? role, bool isActive})> _loadAccess(String uid) async {
    final data = (await _firestore.collection('users').doc(uid).get()).data();
    final roleValue = data?['role'] as String?;
    UserRole? role;
    for (final candidate in UserRole.values) {
      if (candidate.name == roleValue) {
        role = candidate;
      }
    }
    // Missing flag means an account from before the flag mattered; treat
    // it as active rather than locking that user out.
    final isActive = data?['isActive'] as bool? ?? true;
    return (role: role, isActive: isActive);
  }

  AppFailure _mapAuthException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'email-already-in-use' =>
        'An account already exists for this email address.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' => 'The email or password is incorrect.',
      'weak-password' => 'Password must contain at least 8 characters.',
      'operation-not-allowed' =>
        'Email/password authentication is not enabled for this Firebase project.',
      'configuration-not-found' =>
        'Firebase Authentication is not fully configured for this project.',
      'app-not-authorized' =>
        'This app is not authorized to use the configured Firebase project.',
      'api-key-not-valid' => 'The Firebase API key is not valid for this app.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to complete authentication. Please try again.',
    };
    return AppFailure(
      message: message,
      type: FailureType.authentication,
      code: error.code,
      technicalDetails: error,
    );
  }

  AppFailure _mapFirebaseException(FirebaseException error) {
    return AppFailure(
      message: 'Unable to load your account data. Please try again.',
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
