import '../../../../core/result/result.dart';
import '../../data/repositories/attendance_repository.dart';

/// Records a student's check-out for today.
class CheckOutUseCase {
  /// Creates a check-out use case.
  const CheckOutUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Executes the check-out workflow. The student's identity is passed
  /// through because the audit event written alongside the check-out
  /// names who acted, and the caller already has it loaded.
  Future<Result<void>> call({
    required String internshipId,
    required String studentId,
    required String studentName,
  }) {
    return _repository.checkOut(
      internshipId: internshipId,
      studentId: studentId,
      studentName: studentName,
    );
  }
}
