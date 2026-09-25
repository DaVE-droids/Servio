import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/internship_status.dart';
import 'package:servio/features/internship/data/models/internship_model.dart';

void main() {
  test('serializes DDS internship fields with pending_review status', () {
    final internship = InternshipModel(
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      status: InternshipStatus.pendingReview,
      companyName: 'MTN Nigeria',
      companyAddress: 'Victoria Island, Lagos',
      companyLatitude: 6.4281,
      companyLongitude: 3.4219,
      companySupervisorName: 'Jane Doe',
      companySupervisorPhone: '+2348012345678',
      department: 'Computer Science',
      country: 'Nigeria',
      state: 'Lagos',
      startDate: DateTime.utc(2026, 8),
      endDate: DateTime.utc(2026, 12),
      submittedAt: DateTime.utc(2026, 7, 31),
      createdAt: DateTime.utc(2026, 7, 31),
      updatedAt: DateTime.utc(2026, 7, 31),
    );

    final json = internship.toJson();

    expect(json['internshipId'], 'int-1');
    expect(json['studentId'], 'student-1');
    expect(json['status'], 'pending_review');
    expect(json['companyName'], 'MTN Nigeria');
    expect(json['companyLatitude'], 6.4281);
    expect(json['companyLongitude'], 3.4219);
    expect(json['lecturerId'], isNull);
    expect(json['coordinatorId'], isNull);
  });

  test('parses Firestore status values and timestamps', () {
    final internship = InternshipModel.fromJson({
      'internshipId': 'int-1',
      'studentId': 'student-1',
      'studentName': 'David Adeyemi',
      'studentMatricNumber': 'CSC/2022/001',
      'lecturerId': null,
      'coordinatorId': null,
      'status': 'approved',
      'companyName': 'MTN Nigeria',
      'companyAddress': 'Victoria Island, Lagos',
      'companyLatitude': 6.4281,
      'companyLongitude': 3.4219,
      'companySupervisorName': 'Jane Doe',
      'companySupervisorPhone': '+2348012345678',
      'department': 'Computer Science',
      'country': 'Nigeria',
      'state': 'Lagos',
      'startDate': '2026-08-01T00:00:00.000Z',
      'endDate': '2026-12-01T00:00:00.000Z',
      'submittedAt': '2026-07-31T00:00:00.000Z',
      'approvedAt': null,
      'assignedAt': null,
      'completedAt': null,
      'createdAt': '2026-07-31T00:00:00.000Z',
      'updatedAt': '2026-07-31T00:00:00.000Z',
    });

    expect(internship.status, InternshipStatus.approved);
    expect(internship.startDate, DateTime.utc(2026, 8));
    expect(internship.endDate, DateTime.utc(2026, 12));
  });

  test('round-trips a rejected internship with rejectedAt', () {
    final internship = InternshipModel(
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      coordinatorId: 'coordinator-1',
      status: InternshipStatus.rejected,
      companyName: 'MTN Nigeria',
      companyAddress: 'Victoria Island, Lagos',
      companyLatitude: 6.4281,
      companyLongitude: 3.4219,
      companySupervisorName: 'Jane Doe',
      companySupervisorPhone: '+2348012345678',
      department: 'Computer Science',
      country: 'Nigeria',
      state: 'Lagos',
      startDate: DateTime.utc(2026, 8),
      endDate: DateTime.utc(2026, 12),
      submittedAt: DateTime.utc(2026, 7, 31),
      rejectedAt: DateTime.utc(2026, 8, 1),
      createdAt: DateTime.utc(2026, 7, 31),
      updatedAt: DateTime.utc(2026, 8, 1),
    );

    final json = internship.toJson();
    expect(json['status'], 'rejected');
    expect(json['coordinatorId'], 'coordinator-1');
    expect(json['approvedAt'], isNull);

    final roundTripped = InternshipModel.fromJson(json);
    expect(roundTripped.status, InternshipStatus.rejected);
    expect(roundTripped.rejectedAt, DateTime.utc(2026, 8, 1));
  });

  test('round-trips an assigned internship with lecturerId and assignedAt', () {
    final internship = InternshipModel(
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      coordinatorId: 'coordinator-1',
      lecturerId: 'lecturer-1',
      status: InternshipStatus.assigned,
      companyName: 'MTN Nigeria',
      companyAddress: 'Victoria Island, Lagos',
      companyLatitude: 6.4281,
      companyLongitude: 3.4219,
      companySupervisorName: 'Jane Doe',
      companySupervisorPhone: '+2348012345678',
      department: 'Computer Science',
      country: 'Nigeria',
      state: 'Lagos',
      startDate: DateTime.utc(2026, 8),
      endDate: DateTime.utc(2026, 12),
      submittedAt: DateTime.utc(2026, 7, 31),
      approvedAt: DateTime.utc(2026, 8, 1),
      assignedAt: DateTime.utc(2026, 8, 2),
      createdAt: DateTime.utc(2026, 7, 31),
      updatedAt: DateTime.utc(2026, 8, 2),
    );

    final json = internship.toJson();
    expect(json['status'], 'assigned');
    expect(json['lecturerId'], 'lecturer-1');
    expect(json['rejectedAt'], isNull);

    final roundTripped = InternshipModel.fromJson(json);
    expect(roundTripped.status, InternshipStatus.assigned);
    expect(roundTripped.lecturerId, 'lecturer-1');
    expect(roundTripped.assignedAt, DateTime.utc(2026, 8, 2));
  });

  test(
    'round-trips an active internship with lecturerName and activatedAt',
    () {
      final internship = InternshipModel(
        internshipId: 'int-1',
        studentId: 'student-1',
        studentName: 'David Adeyemi',
        studentMatricNumber: 'CSC/2022/001',
        coordinatorId: 'coordinator-1',
        lecturerId: 'lecturer-1',
        lecturerName: 'Dr. Samuel Johnson',
        status: InternshipStatus.active,
        companyName: 'MTN Nigeria',
        companyAddress: 'Victoria Island, Lagos',
        companyLatitude: 6.4281,
        companyLongitude: 3.4219,
        companySupervisorName: 'Jane Doe',
        companySupervisorPhone: '+2348012345678',
        department: 'Computer Science',
        country: 'Nigeria',
        state: 'Lagos',
        startDate: DateTime.utc(2026, 8),
        endDate: DateTime.utc(2026, 12),
        submittedAt: DateTime.utc(2026, 7, 31),
        approvedAt: DateTime.utc(2026, 8, 1),
        assignedAt: DateTime.utc(2026, 8, 2),
        activatedAt: DateTime.utc(2026, 8, 3),
        createdAt: DateTime.utc(2026, 7, 31),
        updatedAt: DateTime.utc(2026, 8, 3),
      );

      final json = internship.toJson();
      expect(json['status'], 'active');
      expect(json['lecturerName'], 'Dr. Samuel Johnson');

      final roundTripped = InternshipModel.fromJson(json);
      expect(roundTripped.status, InternshipStatus.active);
      expect(roundTripped.lecturerName, 'Dr. Samuel Johnson');
      expect(roundTripped.activatedAt, DateTime.utc(2026, 8, 3));
    },
  );

  test('parses a placement stored before the country field existed', () {
    final internship = InternshipModel.fromJson({
      'internshipId': 'int-old',
      'studentId': 'student-1',
      'studentName': 'IBK Osobu',
      'studentMatricNumber': 'RUN/22/CPE/12567',
      'status': 'active',
      'companyName': 'Maybe',
      'companyAddress': 'Ikeja',
      'companyLatitude': 6.6,
      'companyLongitude': 3.3,
      'companySupervisorName': 'Jane Doe',
      'companySupervisorPhone': '+2348012345678',
      'department': 'CPE',
      'state': 'Lagos',
      'startDate': '2026-08-01T00:00:00.000Z',
      'endDate': '2026-12-01T00:00:00.000Z',
      'submittedAt': '2026-07-31T00:00:00.000Z',
      'createdAt': '2026-07-31T00:00:00.000Z',
      'updatedAt': '2026-07-31T00:00:00.000Z',
    });
    expect(internship.country, isEmpty);
    expect(internship.status, InternshipStatus.active);
  });
}
