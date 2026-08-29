/// Student-entered placement details for internship submission.
class InternshipSubmissionRequest {
  /// Creates an internship submission request.
  const InternshipSubmissionRequest({
    required this.companyName,
    required this.companyAddress,
    required this.companySupervisorName,
    required this.companySupervisorPhone,
    required this.state,
    required this.startDate,
    required this.endDate,
  });

  /// Host company name.
  final String companyName;

  /// Formatted company address. Geocoded into coordinates during
  /// submission, so no lat/long fields are collected here.
  final String companyAddress;

  /// Company supervisor name.
  final String companySupervisorName;

  /// Company supervisor phone number.
  final String companySupervisorPhone;

  /// Company state.
  final String state;

  /// Internship start date.
  final DateTime startDate;

  /// Internship end date.
  final DateTime endDate;
}
