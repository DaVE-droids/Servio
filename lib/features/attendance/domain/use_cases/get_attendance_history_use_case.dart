import '../../../../core/result/result.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';

/// Retrieves recent attendance history for a student.
class GetAttendanceHistoryUseCase {
  /// Creates a get-attendance-history use case.
  const GetAttendanceHistoryUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the lookup.
  Future<Result<List<AttendanceModel>>> call(
    String studentId, {
    String? lecturerId,
  }) {
    return _repository.getAttendanceHistory(studentId, lecturerId: lecturerId);
  }
}
