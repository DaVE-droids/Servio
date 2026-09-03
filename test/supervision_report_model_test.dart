import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/supervision/data/models/supervision_report_model.dart';

void main() {
  test('round-trips a supervision report', () {
    final report = SupervisionReportModel(
      reportId: 'sup-1',
      internshipId: 'int-1',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      visitDate: DateTime.utc(2026, 8, 30, 10),
      studentPresent: true,
      companyRepresentativePresent: true,
      observation: 'Student demonstrates strong technical ability.',
      recommendations: 'Continue exposing the student to production systems.',
      rating: 5,
      photoUrls: const [],
      createdAt: DateTime.utc(2026, 8, 30, 12),
    );

    final json = report.toJson();
    expect(json['reportId'], 'sup-1');
    expect(json['studentPresent'], isTrue);
    expect(json['companyRepresentativePresent'], isTrue);
    expect(json['rating'], 5);
    expect(json['photoUrls'], isEmpty);

    final roundTripped = SupervisionReportModel.fromJson(json);
    expect(roundTripped.reportId, 'sup-1');
    expect(roundTripped.studentPresent, isTrue);
    expect(roundTripped.rating, 5);
    expect(
      roundTripped.observation,
      'Student demonstrates strong technical ability.',
    );
  });

  test('round-trips a report where the student was absent', () {
    final report = SupervisionReportModel(
      reportId: 'sup-2',
      internshipId: 'int-1',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      visitDate: DateTime.utc(2026, 9, 1, 9),
      studentPresent: false,
      companyRepresentativePresent: false,
      observation: 'Neither the student nor a representative was available.',
      recommendations: 'Reschedule the visit.',
      rating: 2,
      photoUrls: const [],
      createdAt: DateTime.utc(2026, 9, 1, 11),
    );

    final json = report.toJson();
    final roundTripped = SupervisionReportModel.fromJson(json);
    expect(roundTripped.studentPresent, isFalse);
    expect(roundTripped.companyRepresentativePresent, isFalse);
    expect(roundTripped.rating, 2);
  });
}
