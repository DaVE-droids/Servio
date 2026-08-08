/// Email and password input for login.
class LoginRequest {
  /// Creates a login request.
  const LoginRequest({required this.email, required this.password});

  /// User email address.
  final String email;

  /// User password.
  final String password;
}

/// Email and password input for student registration.
class RegisterRequest {
  /// Creates a registration request.
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.department,
    required this.matricNumber,
    this.phoneNumber,
    this.faculty,
  });

  /// Student first name.
  final String firstName;

  /// Student last name.
  final String lastName;

  /// Student email address.
  final String email;

  /// Student password.
  final String password;

  /// Academic department.
  final String department;

  /// Student matric number.
  final String matricNumber;

  /// Optional phone number.
  final String? phoneNumber;

  /// Optional faculty.
  final String? faculty;
}
