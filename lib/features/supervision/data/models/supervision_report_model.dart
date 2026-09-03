import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for documents in `supervision_reports`.
class SupervisionReportModel {
  /// Creates a supervision report model.
  const SupervisionReportModel({
    required this.reportId,
    required this.internshipId,
    required this.lecturerId,
    required this.lecturerName,
    required this.studentId,
    required this.studentName,
    required this.studentMatricNumber,
    required this.companyName,
    required this.state,
    required this.visitDate,
    required this.studentPresent,
    required this.companyRepresentativePresent,
    required this.observation,
    required this.recommendations,
    required this.rating,
    required this.photoUrls,
    required this.createdAt,
  });

  /// Supervision report document ID.
  final String reportId;

  /// Related internship ID.
  final String internshipId;

  /// Assigned lecturer ID.
  final String lecturerId;

  /// Denormalized lecturer name.
  final String lecturerName;

  /// Student user ID.
  final String studentId;

  /// Denormalized student name.
  final String studentName;

  /// Denormalized student matric number.
  final String studentMatricNumber;

  /// Denormalized host company name.
  final String companyName;

  /// Denormalized company state.
  final String state;

  /// Visit date and time.
  final DateTime visitDate;

  /// Whether the student was present during the visit.
  final bool studentPresent;

  /// Whether a company representative was present during the visit.
  final bool companyRepresentativePresent;

  /// General observation recorded by the lecturer.
  final String observation;

  /// Recommendations recorded by the lecturer.
  final String recommendations;

  /// Overall rating, 1 to 5.
  final int rating;

  /// Supporting photo URLs. Always empty for now — upload isn't built yet
  /// (FR-SUP-005 is a SHOULD HAVE, not a MUST HAVE).
  final List<String> photoUrls;

  /// Creation timestamp. There is no `updatedAt` — reports are immutable
  /// after submission (BR-SUP-002), matching the DDS's literal field list.
  final DateTime createdAt;

  /// Creates a supervision report from JSON.
  factory SupervisionReportModel.fromJson(Map<String, dynamic> json) {
    return SupervisionReportModel(
      reportId: json['reportId'] as String,
      internshipId: json['internshipId'] as String,
      lecturerId: json['lecturerId'] as String,
      lecturerName: json['lecturerName'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentMatricNumber: json['studentMatricNumber'] as String,
      companyName: json['companyName'] as String,
      state: json['state'] as String,
      visitDate: _readDateTime(json['visitDate']),
      studentPresent: json['studentPresent'] as bool,
      companyRepresentativePresent:
          json['companyRepresentativePresent'] as bool,
      observation: json['observation'] as String,
      recommendations: json['recommendations'] as String,
      rating: (json['rating'] as num).toInt(),
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? const [])
          .cast<String>(),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'internshipId': internshipId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'studentId': studentId,
      'studentName': studentName,
      'studentMatricNumber': studentMatricNumber,
      'companyName': companyName,
      'state': state,
      'visitDate': Timestamp.fromDate(visitDate.toUtc()),
      'studentPresent': studentPresent,
      'companyRepresentativePresent': companyRepresentativePresent,
      'observation': observation,
      'recommendations': recommendations,
      'rating': rating,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }
}

DateTime _readDateTime(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate().toUtc(),
    String text => DateTime.parse(text).toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };
}
