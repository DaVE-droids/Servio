/// Validation helpers for lecturer supervision visit reports.
abstract final class SupervisionValidator {
  /// Validates required text fields.
  static String? requiredText(String value, String label) {
    if (value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  /// Validates the overall rating is within the 1-5 scale.
  static String? rating(int? value) {
    if (value == null) {
      return 'Overall rating is required.';
    }
    if (value < 1 || value > 5) {
      return 'Rating must be between 1 and 5.';
    }
    return null;
  }

  /// Validates the visit date/time was selected.
  static String? visitDate(DateTime? value) {
    if (value == null) {
      return 'Visit date and time are required.';
    }
    return null;
  }
}
