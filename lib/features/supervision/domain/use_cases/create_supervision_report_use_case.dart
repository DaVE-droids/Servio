import '../../../../core/result/result.dart';
import '../../data/models/supervision_report_model.dart';
import '../../data/models/supervision_report_request.dart';
import '../../data/repositories/supervision_repository.dart';

/// Use case for submitting a lecturer supervision visit report.
class CreateSupervisionReportUseCase {
  /// Creates a supervision report use case.
  const CreateSupervisionReportUseCase(this._repository);

  final SupervisionRepository _repository;

  /// Executes the visit report submission.
  Future<Result<SupervisionReportModel>> call({
    required String lecturerId,
    required String lecturerName,
    required String studentId,
    required String studentName,
    required String studentMatricNumber,
    required String companyName,
    required String state,
    required SupervisionReportRequest request,
  }) {
    return _repository.createReport(
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      studentId: studentId,
      studentName: studentName,
      studentMatricNumber: studentMatricNumber,
      companyName: companyName,
      state: state,
      request: request,
    );
  }
}
