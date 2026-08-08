import '../../../../core/result/result.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';

/// Use case placeholder for attendance check-in.
class CheckInUseCase {
  /// Creates a check-in use case.
  const CheckInUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the placeholder check-in workflow.
  Future<Result<AttendanceModel?>> call() => _repository.getTodayAttendance();
}
