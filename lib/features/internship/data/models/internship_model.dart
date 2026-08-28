import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/internship_status.dart';

/// Firestore model for documents in `internships`.
class InternshipModel {
  /// Creates an internship model.
  const InternshipModel({
    required this.internshipId,
    required this.studentId,
    required this.status,
    required this.companyName,
    required this.companyAddress,
    required this.companyLatitude,
    required this.companyLongitude,
    required this.companySupervisorName,
    required this.companySupervisorPhone,
    required this.department,
    required this.state,
    required this.startDate,
    required this.endDate,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    this.lecturerId,
    this.coordinatorId,
    this.approvedAt,
    this.rejectedAt,
    this.assignedAt,
    this.completedAt,
  });

  /// Internship document ID.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Assigned lecturer ID, nullable until assigned.
  final String? lecturerId;

  /// Coordinator ID, optional until reviewed.
  final String? coordinatorId;

  /// Internship lifecycle status.
  final InternshipStatus status;

  /// Host company name.
  final String companyName;

  /// Formatted company address.
  final String companyAddress;

  /// Company latitude.
  final double companyLatitude;

  /// Company longitude.
  final double companyLongitude;

  /// Company supervisor contact name.
  final String companySupervisorName;

  /// Company supervisor contact phone number.
  final String companySupervisorPhone;

  /// Student department copied from the profile at submission time.
  final String department;

  /// Company state.
  final String state;

  /// Internship start date.
  final DateTime startDate;

  /// Internship end date.
  final DateTime endDate;

  /// Submission timestamp.
  final DateTime submittedAt;

  /// Approval timestamp.
  final DateTime? approvedAt;

  /// Rejection timestamp.
  final DateTime? rejectedAt;

  /// Lecturer assignment timestamp.
  final DateTime? assignedAt;

  /// Completion timestamp.
  final DateTime? completedAt;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Creates an internship model from JSON.
  factory InternshipModel.fromJson(Map<String, dynamic> json) {
    return InternshipModel(
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      lecturerId: json['lecturerId'] as String?,
      coordinatorId: json['coordinatorId'] as String?,
      status: InternshipStatusSerialization.fromFirestore(
        json['status'] as String,
      ),
      companyName: json['companyName'] as String,
      companyAddress: json['companyAddress'] as String,
      companyLatitude: (json['companyLatitude'] as num).toDouble(),
      companyLongitude: (json['companyLongitude'] as num).toDouble(),
      companySupervisorName: json['companySupervisorName'] as String,
      companySupervisorPhone: json['companySupervisorPhone'] as String,
      department: json['department'] as String,
      state: json['state'] as String,
      startDate: _readDateTime(json['startDate']),
      endDate: _readDateTime(json['endDate']),
      submittedAt: _readDateTime(json['submittedAt']),
      approvedAt: _readNullableDateTime(json['approvedAt']),
      rejectedAt: _readNullableDateTime(json['rejectedAt']),
      assignedAt: _readNullableDateTime(json['assignedAt']),
      completedAt: _readNullableDateTime(json['completedAt']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'internshipId': internshipId,
      'studentId': studentId,
      'lecturerId': lecturerId,
      'coordinatorId': coordinatorId,
      'status': status.firestoreValue,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyLatitude': companyLatitude,
      'companyLongitude': companyLongitude,
      'companySupervisorName': companySupervisorName,
      'companySupervisorPhone': companySupervisorPhone,
      'department': department,
      'state': state,
      'startDate': Timestamp.fromDate(startDate.toUtc()),
      'endDate': Timestamp.fromDate(endDate.toUtc()),
      'submittedAt': Timestamp.fromDate(submittedAt.toUtc()),
      'approvedAt': _writeNullableDateTime(approvedAt),
      'rejectedAt': _writeNullableDateTime(rejectedAt),
      'assignedAt': _writeNullableDateTime(assignedAt),
      'completedAt': _writeNullableDateTime(completedAt),
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }

  /// Returns a copy with selected fields changed.
  InternshipModel copyWith({InternshipStatus? status}) {
    return InternshipModel(
      internshipId: internshipId,
      studentId: studentId,
      lecturerId: lecturerId,
      coordinatorId: coordinatorId,
      status: status ?? this.status,
      companyName: companyName,
      companyAddress: companyAddress,
      companyLatitude: companyLatitude,
      companyLongitude: companyLongitude,
      companySupervisorName: companySupervisorName,
      companySupervisorPhone: companySupervisorPhone,
      department: department,
      state: state,
      startDate: startDate,
      endDate: endDate,
      submittedAt: submittedAt,
      approvedAt: approvedAt,
      rejectedAt: rejectedAt,
      assignedAt: assignedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
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
