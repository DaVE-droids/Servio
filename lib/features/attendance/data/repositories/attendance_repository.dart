import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/attendance_model.dart';

/// Repository placeholder for daily attendance operations.
class AttendanceRepository {
  /// Creates an attendance repository.
  const AttendanceRepository();

  /// Placeholder contract for today's attendance.
  Future<Result<AttendanceModel?>> getTodayAttendance() async {
    return const Failure(
      AppFailure(message: 'Attendance logic is not implemented yet.'),
    );
  }
}
