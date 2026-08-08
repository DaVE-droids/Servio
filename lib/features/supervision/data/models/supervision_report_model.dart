/// Firestore model placeholder for documents in `supervision_reports`.
class SupervisionReportModel {
  /// Creates a supervision report model.
  const SupervisionReportModel({
    required this.reportId,
    required this.internshipId,
    required this.lecturerId,
    required this.studentId,
    required this.visitDate,
  });

  /// Supervision report document ID.
  final String reportId;

  /// Related internship ID.
  final String internshipId;

  /// Assigned lecturer ID.
  final String lecturerId;

  /// Student user ID.
  final String studentId;

  /// Visit date.
  final DateTime visitDate;

  /// Creates a supervision report from JSON.
  factory SupervisionReportModel.fromJson(Map<String, dynamic> json) {
    return SupervisionReportModel(
      reportId: json['reportId'] as String,
      internshipId: json['internshipId'] as String,
      lecturerId: json['lecturerId'] as String,
      studentId: json['studentId'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'internshipId': internshipId,
      'lecturerId': lecturerId,
      'studentId': studentId,
      'visitDate': visitDate.toIso8601String(),
    };
  }

  /// Returns this report unchanged until business fields are implemented.
  SupervisionReportModel copyWith() => this;
}
