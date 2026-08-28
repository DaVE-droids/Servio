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

  /// Validates latitude text.
  static String? latitude(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Latitude is required.';
    }
    if (parsed < -90 || parsed > 90) {
      return 'Latitude must be between -90 and 90.';
    }
    return null;
  }

  /// Validates longitude text.
  static String? longitude(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Longitude is required.';
    }
    if (parsed < -180 || parsed > 180) {
      return 'Longitude must be between -180 and 180.';
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
