import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/attendance_status.dart';

/// Firestore model for documents in `attendance`.
class AttendanceModel {
  /// Creates an attendance model.
  const AttendanceModel({
    required this.attendanceId,
    required this.internshipId,
    required this.studentId,
    required this.studentName,
    required this.studentMatricNumber,
    required this.lecturerId,
    required this.lecturerName,
    required this.companyName,
    required this.state,
    required this.date,
    required this.checkInTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAccuracyMetres,
    this.checkInDistanceMetres,
    this.checkInLocationMocked = false,
    this.checkOutLatitude,
    this.checkOutLongitude,
  });

  /// Attendance document ID (deterministic: `{internshipId}_{yyyy-MM-dd}`).
  final String attendanceId;

  /// Related internship ID.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Denormalized student name.
  final String studentName;

  /// Denormalized student matric number.
  final String studentMatricNumber;

  /// Assigned lecturer ID.
  final String lecturerId;

  /// Denormalized lecturer name.
  final String lecturerName;

  /// Denormalized company name.
  final String companyName;

  /// Denormalized internship state.
  final String state;

  /// Attendance date (midnight UTC of the working day).
  final DateTime date;

  /// Check-in timestamp.
  final DateTime checkInTime;

  /// Check-out timestamp, if checked out.
  final DateTime? checkOutTime;

  /// Check-in latitude, when the device could be located.
  final double? checkInLatitude;

  /// Check-in longitude, when the device could be located.
  final double? checkInLongitude;

  /// The check-in reading's margin of error in metres, as the platform
  /// reported it. Kept so a vague reading is not mistaken for proof.
  final double? checkInAccuracyMetres;

  /// Metres between the check-in reading and the company address.
  ///
  /// Stored rather than recomputed so the record still means something if
  /// the placement's address is ever corrected.
  final double? checkInDistanceMetres;

  /// Whether the device said the check-in position came from a mock
  /// location provider. Android only.
  final bool checkInLocationMocked;

  /// Check-out latitude. Not currently captured.
  final double? checkOutLatitude;

  /// Check-out longitude. Not currently captured.
  final double? checkOutLongitude;

  /// Attendance lifecycle status.
  final AttendanceStatus status;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Creates an attendance model from JSON.
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId'] as String,
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentMatricNumber: json['studentMatricNumber'] as String,
      lecturerId: json['lecturerId'] as String,
      lecturerName: json['lecturerName'] as String,
      companyName: json['companyName'] as String,
      state: json['state'] as String,
      date: _readDateTime(json['date']),
      checkInTime: _readDateTime(json['checkInTime']),
      checkOutTime: _readNullableDateTime(json['checkOutTime']),
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble(),
      checkInAccuracyMetres: (json['checkInAccuracyMetres'] as num?)
          ?.toDouble(),
      checkInDistanceMetres: (json['checkInDistanceMetres'] as num?)
          ?.toDouble(),
      checkInLocationMocked: json['checkInLocationMocked'] as bool? ?? false,
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      status: AttendanceStatusSerialization.fromFirestore(
        json['status'] as String,
      ),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'internshipId': internshipId,
      'studentId': studentId,
      'studentName': studentName,
      'studentMatricNumber': studentMatricNumber,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'companyName': companyName,
      'state': state,
      'date': Timestamp.fromDate(date.toUtc()),
      'checkInTime': Timestamp.fromDate(checkInTime.toUtc()),
      'checkOutTime': _writeNullableDateTime(checkOutTime),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInAccuracyMetres': checkInAccuracyMetres,
      'checkInDistanceMetres': checkInDistanceMetres,
      'checkInLocationMocked': checkInLocationMocked,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'status': status.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
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

DateTime? _readNullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return _readDateTime(value);
}

Timestamp? _writeNullableDateTime(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value.toUtc());
}
