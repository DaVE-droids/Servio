import '../../../../core/enums/internship_status.dart';

/// Firestore model placeholder for documents in `internships`.
class InternshipModel {
  /// Creates an internship model.
  const InternshipModel({
    required this.internshipId,
    required this.studentId,
    required this.status,
    required this.companyName,
  });

  /// Internship document ID.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Internship lifecycle status.
  final InternshipStatus status;

  /// Host company name.
  final String companyName;

  /// Creates an internship model from JSON.
  factory InternshipModel.fromJson(Map<String, dynamic> json) {
    return InternshipModel(
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      status: InternshipStatus.values.byName(json['status'] as String),
      companyName: json['companyName'] as String,
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'internshipId': internshipId,
      'studentId': studentId,
      'status': status.name,
      'companyName': companyName,
    };
  }

  /// Returns a copy with selected fields changed.
  InternshipModel copyWith({InternshipStatus? status}) {
    return InternshipModel(
      internshipId: internshipId,
      studentId: studentId,
      status: status ?? this.status,
      companyName: companyName,
    );
  }
}
