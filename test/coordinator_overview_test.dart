import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/internship_status.dart';
import 'package:servio/core/enums/user_role.dart';
import 'package:servio/features/coordinator/domain/coordinator_overview.dart';
import 'package:servio/features/internship/data/models/internship_model.dart';
import 'package:servio/features/profile/data/models/user_model.dart';
import 'package:servio/features/reports/data/models/internship_progress.dart';

UserModel _user(String uid, UserRole role, {bool isActive = true, String department = 'Computer Science'}) {
  return UserModel(
    uid: uid,
    firstName: uid,
    lastName: 'Test',
    email: '$uid@servio.test',
    role: role,
    department: department,
    isEmailVerified: true,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 9),
    updatedAt: DateTime.utc(2026, 9),
  );
}

InternshipModel _internship(
  String id,
  String studentId,
  InternshipStatus status, {
  String? lecturerId,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 9, 1);
  return InternshipModel(
    internshipId: id,
    studentId: studentId,
    studentName: studentId,
    studentMatricNumber: 'CSC/2022/001',
    lecturerId: lecturerId,
    status: status,
    companyName: 'Company $id',
    companyAddress: 'Lagos',
    companyLatitude: 6.4,
    companyLongitude: 3.4,
    companySupervisorName: 'Supervisor',
    companySupervisorPhone: '+2348000000000',
    department: 'Computer Science',
    country: 'Nigeria',
    state: 'Lagos',
    startDate: created,
    endDate: created.add(const Duration(days: 90)),
    submittedAt: created,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  group('CoordinatorOverview.internshipFor', () {
    test('prefers a resubmission over an earlier rejected placement', () {
      final overview = CoordinatorOverview(
        students: [_user('amaka', UserRole.student)],
        lecturers: const [],
        internships: [
          _internship('old', 'amaka', InternshipStatus.rejected,
              createdAt: DateTime.utc(2026, 9, 1)),
          _internship('new', 'amaka', InternshipStatus.pendingReview,
              createdAt: DateTime.utc(2026, 9, 5)),
        ],
        progress: const {},
      );
      expect(overview.internshipFor('amaka')?.internshipId, 'new');
    });

    test('a non-rejected placement wins even if the rejected one is newer', () {
      final overview = CoordinatorOverview(
        students: [_user('amaka', UserRole.student)],
        lecturers: const [],
        internships: [
          _internship('active', 'amaka', InternshipStatus.active,
              createdAt: DateTime.utc(2026, 9, 1)),
          _internship('stray', 'amaka', InternshipStatus.rejected,
              createdAt: DateTime.utc(2026, 9, 9)),
        ],
        progress: const {},
      );
      expect(overview.internshipFor('amaka')?.internshipId, 'active');
    });

    test('returns null for a student with no placement', () {
      final overview = CoordinatorOverview(
        students: [_user('fatima', UserRole.student)],
        lecturers: const [],
        internships: const [],
        progress: const {},
      );
      expect(overview.internshipFor('fatima'), isNull);
    });
  });

  group('CoordinatorOverview lecturer workload', () {
    final overview = CoordinatorOverview(
      students: const [],
      lecturers: [
        _user('eze', UserRole.lecturer),
        _user('obi', UserRole.lecturer, isActive: false),
      ],
      internships: [
        _internship('a', 's1', InternshipStatus.assigned, lecturerId: 'eze'),
        _internship('b', 's2', InternshipStatus.active, lecturerId: 'eze'),
        _internship('c', 's3', InternshipStatus.completed, lecturerId: 'eze'),
      ],
      progress: const {},
    );

    test('current load excludes completed placements', () {
      expect(overview.activeLoadFor('eze').map((i) => i.internshipId), ['a', 'b']);
    });

    test('all-time supervision includes completed placements', () {
      expect(overview.allSupervisedBy('eze').length, 3);
    });

    test('separates lecturers awaiting approval from approved ones', () {
      expect(overview.pendingLecturers.map((l) => l.uid), ['obi']);
      expect(overview.activeLecturers.map((l) => l.uid), ['eze']);
    });
  });

  test('statusCounts buckets students by their current placement', () {
    final overview = CoordinatorOverview(
      students: [
        _user('a', UserRole.student),
        _user('b', UserRole.student),
        _user('c', UserRole.student),
      ],
      lecturers: const [],
      internships: [
        _internship('1', 'a', InternshipStatus.active),
        _internship('2', 'b', InternshipStatus.active),
      ],
      progress: const {},
    );
    expect(overview.statusCounts[InternshipStatus.active], 2);
    expect(overview.statusCounts[null], 1, reason: 'c has no placement');
  });

  test('progressFor falls back to zeros for untracked placements', () {
    final overview = CoordinatorOverview(
      students: const [],
      lecturers: const [],
      internships: const [],
      progress: const {
        'tracked': InternshipProgress(
          attendanceDays: 3,
          logbookEntries: 2,
          logbookApproved: 1,
          visits: 1,
        ),
      },
    );
    expect(overview.progressFor('tracked').attendanceDays, 3);
    expect(overview.progressFor('missing').visits, 0);
  });

  test('departments are distinct and sorted', () {
    final overview = CoordinatorOverview(
      students: [
        _user('a', UserRole.student, department: 'Electrical Engineering'),
        _user('b', UserRole.student, department: 'Computer Science'),
        _user('c', UserRole.student, department: 'Computer Science'),
      ],
      lecturers: const [],
      internships: const [],
      progress: const {},
    );
    expect(overview.departments, ['Computer Science', 'Electrical Engineering']);
  });
}
