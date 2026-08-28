import '../../../../core/result/result.dart';
import '../../data/models/attendance_check_in_request.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';

/// Records a student's check-in for today.
class CheckInUseCase {
  /// Creates a check-in use case.
  const CheckInUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the check-in workflow.
  Future<Result<AttendanceModel>> call(AttendanceCheckInRequest request) {
    return _repository.checkIn(request);
  }
}
