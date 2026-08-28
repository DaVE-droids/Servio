/// Validation helpers for profile form input.
abstract final class ProfileValidator {
  /// Returns a validation message for names, or null when valid.
  static String? name(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '$label is required.';
    }
    if (trimmed.length < 2) {
      return '$label must contain at least 2 characters.';
    }
    return null;
  }

  /// Returns a validation message for optional phone numbers, or null when valid.
  static String? phoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final pattern = RegExp(r'^\+?[0-9 ]{7,20}$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  /// Returns a validation message for optional profile photo URLs, or null when valid.
  static String? profilePhotoUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return 'Please enter a valid image URL.';
    }
    return null;
  }
}
