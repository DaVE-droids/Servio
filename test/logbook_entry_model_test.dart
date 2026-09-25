import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/logbook_status.dart';
import 'package:servio/features/logbook/data/models/logbook_entry_model.dart';

void main() {
  test('round-trips a pending logbook entry', () {
    final entry = LogbookEntryModel(
      entryId: 'int-1_2026-08-28',
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      date: DateTime.utc(2026, 8, 28),
      activities: 'Implemented authentication module.',
      skillsLearned: 'Firebase Authentication',
      challenges: 'Email verification flow',
      solutionsApplied: 'Used auth state listener',
      hoursWorked: 8,
      status: LogbookStatus.pending,
      createdAt: DateTime.utc(2026, 8, 28, 17),
      updatedAt: DateTime.utc(2026, 8, 28, 17),
    );

    final json = entry.toJson();
    expect(json['entryId'], 'int-1_2026-08-28');
    expect(json['status'], 'pending');
    expect(json['lecturerComments'], isNull);
    expect(json['attachmentUrls'], isEmpty);

    final roundTripped = LogbookEntryModel.fromJson(json);
    expect(roundTripped.status, LogbookStatus.pending);
    expect(roundTripped.activities, 'Implemented authentication module.');
    expect(roundTripped.hoursWorked, 8);
  });

  test('round-trips a changes-requested entry with lecturer comments', () {
    final entry = LogbookEntryModel(
      entryId: 'int-1_2026-08-28',
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      date: DateTime.utc(2026, 8, 28),
      activities: 'Implemented authentication module.',
      skillsLearned: 'Firebase Authentication',
      challenges: 'Email verification flow',
      solutionsApplied: 'Used auth state listener',
      hoursWorked: 8,
      status: LogbookStatus.changesRequested,
      lecturerComments: 'Please add more detail on the challenges faced.',
      createdAt: DateTime.utc(2026, 8, 28, 17),
      updatedAt: DateTime.utc(2026, 8, 29, 9),
    );

    final json = entry.toJson();
    expect(json['status'], 'changes_requested');
    expect(
      json['lecturerComments'],
      'Please add more detail on the challenges faced.',
    );

    final roundTripped = LogbookEntryModel.fromJson(json);
    expect(roundTripped.status, LogbookStatus.changesRequested);
    expect(
      roundTripped.lecturerComments,
      'Please add more detail on the challenges faced.',
    );
  });
}
