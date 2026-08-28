/// Editable profile fields a user is permitted to update from the profile screen.
class ProfileUpdateRequest {
  /// Creates a profile update request.
  const ProfileUpdateRequest({
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.faculty,
    this.profilePhotoUrl,
  });

  /// User's first name.
  final String firstName;

  /// User's last name.
  final String lastName;

  /// Optional contact number.
  final String? phoneNumber;

  /// Optional faculty or school.
  final String? faculty;

  /// Optional Firebase Storage URL or externally provisioned profile photo URL.
  final String? profilePhotoUrl;

  /// Converts only permitted editable fields to Firestore updates.
  Map<String, Object?> toEditableJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phoneNumber': _nullableTrim(phoneNumber),
      'faculty': _nullableTrim(faculty),
      'profilePhotoUrl': _nullableTrim(profilePhotoUrl),
    };
  }
}

String? _nullableTrim(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
