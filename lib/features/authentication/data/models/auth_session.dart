import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/enums/user_role.dart';

/// Current authentication session resolved from Firebase Auth and Firestore role data.
class AuthSession {
  /// Creates an authentication session.
  const AuthSession({
    required this.firebaseUser,
    required this.isEmailVerified,
    this.role,
  });

  /// Signed-in Firebase user, or null when signed out.
  final User? firebaseUser;

  /// Whether the signed-in user's email is verified.
  final bool isEmailVerified;

  /// Application role loaded from `users/{uid}`.
  final UserRole? role;

  /// Whether a Firebase user is currently signed in.
  bool get isAuthenticated => firebaseUser != null;
}
