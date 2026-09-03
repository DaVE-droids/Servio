/// Lecturer-entered visit report details.
class SupervisionReportRequest {
  /// Creates a supervision report request.
  const SupervisionReportRequest({
    required this.internshipId,
    required this.visitDate,
    required this.studentPresent,
    required this.companyRepresentativePresent,
    required this.observation,
    required this.recommendations,
    required this.rating,
  });

  /// Internship being visited.
  final String internshipId;

  /// Combined visit date and time.
  final DateTime visitDate;

  /// Whether the student was present during the visit.
  final bool studentPresent;

  /// Whether a company representative was present during the visit.
  final bool companyRepresentativePresent;

  /// General observation.
  final String observation;

  /// Recommendations.
  final String recommendations;

  /// Overall rating, 1 to 5.
  final int rating;
}
