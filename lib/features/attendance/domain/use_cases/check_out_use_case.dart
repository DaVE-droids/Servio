import '../../../../core/result/result.dart';
import '../../data/repositories/attendance_repository.dart';

/// Records a student's check-out for today.
class CheckOutUseCase {
  /// Creates a check-out use case.
  const CheckOutUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the check-out workflow.
  Future<Result<void>> call(String internshipId) {
    return _repository.checkOut(internshipId);
  }
}
