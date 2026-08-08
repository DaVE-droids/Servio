import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Authentication SDK access.
class AuthService {
  /// Creates an authentication service.
  const AuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  /// Exposes the Firebase authentication state stream.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Returns the current Firebase user, when authenticated.
  User? get currentUser => _firebaseAuth.currentUser;
}
