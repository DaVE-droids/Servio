/// Validation helpers for authentication forms.
abstract final class AuthValidator {
  /// Returns an email validation message, or null when valid.
  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Returns a password validation message, or null when valid.
  static String? password(String value) {
    if (value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must contain at least 8 characters.';
    }
    return null;
  }

  /// Returns a required-field validation message, or null when valid.
  static String? required(String value, String label) {
    if (value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }
}
