/// Student-entered daily logbook details, assembled by the controller from
/// form input plus the already-loaded profile and internship state.
class LogbookEntryRequest {
  /// Creates a logbook entry request.
  const LogbookEntryRequest({
    required this.internshipId,
    required this.studentId,
    required this.studentName,
    required this.studentMatricNumber,
    required this.lecturerId,
    required this.lecturerName,
    required this.companyName,
    required this.state,
    required this.activities,
    required this.skillsLearned,
    required this.challenges,
    required this.solutionsApplied,
    required this.hoursWorked,
  });

  /// Internship this entry belongs to.
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

  /// Activities performed that day.
  final String activities;

  /// Skills learned that day.
  final String skillsLearned;

  /// Challenges encountered that day.
  final String challenges;

  /// Solutions applied to those challenges.
  final String solutionsApplied;

  /// Hours worked that day.
  final num hoursWorked;
}
