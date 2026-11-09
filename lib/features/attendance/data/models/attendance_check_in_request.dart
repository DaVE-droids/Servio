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
    this.deviceLatitude,
    this.deviceLongitude,
    this.deviceAccuracyMetres,
    this.deviceLocationMocked = false,
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

  /// Where the phone said it was when the student tapped check in, or null
  /// if no reading could be taken. Read by the controller rather than the
  /// repository, so the student can be told why it is missing and given the
  /// choice to fix it before anything is written.
  final double? deviceLatitude;

  /// Device longitude, or null alongside a null [deviceLatitude].
  final double? deviceLongitude;

  /// The reading's margin of error in metres, as reported by the platform.
  final double? deviceAccuracyMetres;

  /// Whether the platform said the reading came from a mock provider.
  final bool deviceLocationMocked;
}
