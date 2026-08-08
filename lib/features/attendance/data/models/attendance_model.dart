import '../../../../core/enums/attendance_status.dart';

/// Firestore model placeholder for documents in `attendance`.
class AttendanceModel {
  /// Creates an attendance model.
  const AttendanceModel({
    required this.attendanceId,
    required this.internshipId,
    required this.studentId,
    required this.date,
    required this.status,
  });

  /// Attendance document ID.
  final String attendanceId;

  /// Related internship ID.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Attendance date.
  final DateTime date;

  /// Attendance lifecycle status.
  final AttendanceStatus status;

  /// Creates an attendance model from JSON.
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId'] as String,
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.values.byName(json['status'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'internshipId': internshipId,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.name,
    };
  }

  /// Returns a copy with selected fields changed.
  AttendanceModel copyWith({AttendanceStatus? status}) {
    return AttendanceModel(
      attendanceId: attendanceId,
      internshipId: internshipId,
      studentId: studentId,
      date: date,
      status: status ?? this.status,
    );
  }
}
