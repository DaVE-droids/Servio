import '../../../../core/enums/logbook_status.dart';

/// Firestore model placeholder for documents in `logbook_entries`.
class LogbookEntryModel {
  /// Creates a logbook entry model.
  const LogbookEntryModel({
    required this.entryId,
    required this.internshipId,
    required this.studentId,
    required this.date,
    required this.status,
  });

  /// Logbook entry document ID.
  final String entryId;

  /// Related internship ID.
  final String internshipId;

  /// Student user ID.
  final String studentId;

  /// Entry date.
  final DateTime date;

  /// Review status.
  final LogbookStatus status;

  /// Creates a logbook entry from JSON.
  factory LogbookEntryModel.fromJson(Map<String, dynamic> json) {
    return LogbookEntryModel(
      entryId: json['entryId'] as String,
      internshipId: json['internshipId'] as String,
      studentId: json['studentId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: LogbookStatus.values.byName(json['status'] as String),
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'internshipId': internshipId,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.name,
    };
  }

  /// Returns a copy with selected fields changed.
  LogbookEntryModel copyWith({LogbookStatus? status}) {
    return LogbookEntryModel(
      entryId: entryId,
      internshipId: internshipId,
      studentId: studentId,
      date: date,
      status: status ?? this.status,
    );
  }
}
