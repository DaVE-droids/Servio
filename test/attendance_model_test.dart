import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/attendance_status.dart';
import 'package:servio/features/attendance/data/models/attendance_model.dart';

void main() {
  test('round-trips a checked-in attendance record', () {
    final attendance = AttendanceModel(
      attendanceId: 'int-1_2026-08-28',
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      date: DateTime.utc(2026, 8, 28),
      checkInTime: DateTime.utc(2026, 8, 28, 8, 4),
      status: AttendanceStatus.checkedIn,
      createdAt: DateTime.utc(2026, 8, 28, 8, 4),
      updatedAt: DateTime.utc(2026, 8, 28, 8, 4),
    );

    final json = attendance.toJson();
    expect(json['attendanceId'], 'int-1_2026-08-28');
    expect(json['status'], 'checked_in');
    expect(json['checkOutTime'], isNull);

    final roundTripped = AttendanceModel.fromJson(json);
    expect(roundTripped.status, AttendanceStatus.checkedIn);
    expect(roundTripped.studentName, 'David Adeyemi');
    expect(roundTripped.checkInTime, DateTime.utc(2026, 8, 28, 8, 4));
    expect(roundTripped.checkOutTime, isNull);
  });

  test('round-trips a completed attendance record with check-out', () {
    final attendance = AttendanceModel(
      attendanceId: 'int-1_2026-08-28',
      internshipId: 'int-1',
      studentId: 'student-1',
      studentName: 'David Adeyemi',
      studentMatricNumber: 'CSC/2022/001',
      lecturerId: 'lecturer-1',
      lecturerName: 'Dr. Samuel Johnson',
      companyName: 'MTN Nigeria',
      state: 'Lagos',
      date: DateTime.utc(2026, 8, 28),
      checkInTime: DateTime.utc(2026, 8, 28, 8, 4),
      checkOutTime: DateTime.utc(2026, 8, 28, 17, 0),
      status: AttendanceStatus.completed,
      createdAt: DateTime.utc(2026, 8, 28, 8, 4),
      updatedAt: DateTime.utc(2026, 8, 28, 17, 0),
    );

    final json = attendance.toJson();
    expect(json['status'], 'completed');

    final roundTripped = AttendanceModel.fromJson(json);
    expect(roundTripped.status, AttendanceStatus.completed);
    expect(roundTripped.checkOutTime, DateTime.utc(2026, 8, 28, 17, 0));
  });
}
