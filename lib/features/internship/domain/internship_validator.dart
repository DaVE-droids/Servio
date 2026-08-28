/// Validation helpers for student internship placement submission.
abstract final class InternshipValidator {
  /// Validates required text fields.
  static String? requiredText(String value, String label) {
    if (value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  /// Validates supervisor phone number format.
  static String? phoneNumber(String value) {
    final required = requiredText(value, 'Supervisor phone number');
    if (required != null) {
      return required;
    }
    final pattern = RegExp(r'^\+?[0-9 ]{7,20}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Please enter a valid supervisor phone number.';
    }
    return null;
  }

  /// Validates internship dates.
  static String? dates({
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    if (startDate == null) {
      return 'Start date is required.';
    }
    if (endDate == null) {
      return 'End date is required.';
    }
    if (endDate.isBefore(startDate)) {
      return 'End date cannot be before start date.';
    }
    return null;
  }
}
