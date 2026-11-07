/// Denormalized details needed to record a check-in, assembled by the
/// controller from the already-loaded profile and internship state (see
/// ARS repository dependency rules — repositories don't call one another).
class AttendanceCheckInRequest {
  /// Creates a check-in request.
  const AttendanceCheckInRequest({
    required this.internshipId,
    required this.studentId,
    required this.studentName,
    required this.studentMatricNumber,
    required this.lecturerId,
    required this.lecturerName,
    required this.companyName,
    required this.state,
    required this.companyLatitude,
    required this.companyLongitude,
  });

  /// Internship this attendance record belongs to.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Student display name, from their profile.
  final String studentName;

  /// Student matric number, from their profile.
  final String studentMatricNumber;

  /// Assigned lecturer ID, from the internship.
  final String lecturerId;

  /// Assigned lecturer name, from the internship.
  final String lecturerName;

  /// Company name, from the internship.
  final String companyName;

  /// Internship state, from the internship.
  final String state;

  /// Company latitude, from the internship — the centre of the geofence
  /// the check-in reading is measured against.
  final double companyLatitude;

  /// Company longitude, from the internship.
  final double companyLongitude;
}
