import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/logbook_status.dart';

/// Firestore model for documents in `logbook_entries`.
class LogbookEntryModel {
  /// Creates a logbook entry model.
  const LogbookEntryModel({
    required this.entryId,
    required this.internshipId,
    required this.studentId,
    required this.studentName,
    required this.studentMatricNumber,
    required this.lecturerId,
    required this.lecturerName,
    required this.companyName,
    required this.state,
    required this.date,
    required this.activities,
    required this.skillsLearned,
    required this.challenges,
    required this.solutionsApplied,
    required this.hoursWorked,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrls = const [],
    this.lecturerComments,
  });

  /// Logbook entry document ID (deterministic:
  /// `{internshipId}_{yyyy-MM-dd}`, same reasoning as attendance).
  final String entryId;

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

  /// Entry date (midnight UTC of the working day).
  final DateTime date;

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

  /// Optional supporting attachment URLs. Not currently populated — no
  /// upload UI built yet (FR-LOG-006 is a SHOULD, not a MUST); see
  /// docs/CHANGELOG.md.
  final List<String> attachmentUrls;

  /// Review status.
  final LogbookStatus status;

  /// Lecturer's review comments, if reviewed.
  final String? lecturerComments;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Creates a logbook entry from JSON.
  factory LogbookEntryModel.fromJson(Map<String, dynamic> json) {
    return LogbookEntryModel(
      entryId: json['entryId'] as String,
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentMatricNumber: json['studentMatricNumber'] as String,
      lecturerId: json['lecturerId'] as String,
      lecturerName: json['lecturerName'] as String,
      companyName: json['companyName'] as String,
      state: json['state'] as String,
      date: _readDateTime(json['date']),
      activities: json['activities'] as String,
      skillsLearned: json['skillsLearned'] as String,
      challenges: json['challenges'] as String,
      solutionsApplied: json['solutionsApplied'] as String,
      hoursWorked: json['hoursWorked'] as num,
      attachmentUrls:
          (json['attachmentUrls'] as List<dynamic>?)
              ?.map((url) => url as String)
              .toList() ??
          const [],
      status: LogbookStatusSerialization.fromFirestore(
        json['status'] as String,
      ),
      lecturerComments: json['lecturerComments'] as String?,
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'internshipId': internshipId,
      'studentId': studentId,
      'studentName': studentName,
      'studentMatricNumber': studentMatricNumber,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'companyName': companyName,
      'state': state,
      'date': Timestamp.fromDate(date.toUtc()),
      'activities': activities,
      'skillsLearned': skillsLearned,
      'challenges': challenges,
      'solutionsApplied': solutionsApplied,
      'hoursWorked': hoursWorked,
      'attachmentUrls': attachmentUrls,
      'status': status.firestoreValue,
      'lecturerComments': lecturerComments,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }

  /// Returns a copy with selected fields changed.
  LogbookEntryModel copyWith({
    String? activities,
    String? skillsLearned,
    String? challenges,
    String? solutionsApplied,
    num? hoursWorked,
    LogbookStatus? status,
    String? lecturerComments,
    DateTime? updatedAt,
  }) {
    return LogbookEntryModel(
      entryId: entryId,
      internshipId: internshipId,
      studentId: studentId,
      studentName: studentName,
      studentMatricNumber: studentMatricNumber,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      companyName: companyName,
      state: state,
      date: date,
      activities: activities ?? this.activities,
      skillsLearned: skillsLearned ?? this.skillsLearned,
      challenges: challenges ?? this.challenges,
      solutionsApplied: solutionsApplied ?? this.solutionsApplied,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      attachmentUrls: attachmentUrls,
      status: status ?? this.status,
      lecturerComments: lecturerComments ?? this.lecturerComments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
