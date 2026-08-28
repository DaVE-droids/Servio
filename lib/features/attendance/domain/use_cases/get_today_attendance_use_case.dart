import '../../../../core/result/result.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';

/// Retrieves today's attendance record for an internship, if any.
class GetTodayAttendanceUseCase {
  /// Creates a get-today-attendance use case.
  const GetTodayAttendanceUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the lookup.
  Future<Result<AttendanceModel?>> call(String internshipId) {
    return _repository.getTodayAttendance(internshipId);
  }
}
