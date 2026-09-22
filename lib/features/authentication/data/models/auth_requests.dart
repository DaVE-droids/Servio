import '../../../../core/enums/user_role.dart';

/// Email and password input for login.
class LoginRequest {
  /// Creates a login request.
  const LoginRequest({required this.email, required this.password});

  /// User email address.
  final String email;

  /// User password.
  final String password;
}

/// Input for self-registration. Students and lecturers sign up through the
/// same form; coordinators are created by an administrator.
class RegisterRequest {
  /// Creates a registration request.
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.department,
    required this.idNumber,
    this.role = UserRole.student,
    this.phoneNumber,
    this.faculty,
  });

  /// First name.
  final String firstName;

  /// Last name.
  final String lastName;

  /// Email address.
  final String email;

  /// Password.
  final String password;

  /// Academic department.
  final String department;

  /// The institution-issued ID: a matric number for students, a staff ID
  /// for lecturers. One field because the form only ever asks for one.
  final String idNumber;

  /// Which account type is being created — only [UserRole.student] or
  /// [UserRole.lecturer]; the security rules reject anything else.
  final UserRole role;

  /// Optional phone number.
  final String? phoneNumber;

  /// Optional faculty.
  final String? faculty;
}
