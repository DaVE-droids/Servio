import 'package:firebase_auth/firebase_auth.dart';

/// Feature-level service that wraps Firebase Authentication calls.
class AuthenticationService {
  /// Creates an authentication service.
  const AuthenticationService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  /// Emits Firebase authentication state changes for session persistence.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Returns the current Firebase user, if one exists.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Creates an email/password account.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with email/password.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  /// Reloads the current Firebase user.
  Future<User?> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser;
  }

  /// Signs out the current user.
  Future<void> logout() => _firebaseAuth.signOut();
}
