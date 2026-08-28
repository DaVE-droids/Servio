import '../../../../core/result/result.dart';
import '../../data/models/internship_model.dart';
import '../../data/models/internship_submission_request.dart';
import '../../data/repositories/internship_repository.dart';

/// Use case placeholder for placement submission.
class SubmitInternshipUseCase {
  /// Creates a submit internship use case.
  const SubmitInternshipUseCase(this._repository);

  final InternshipRepository _repository;

  /// Executes student placement submission.
  Future<Result<InternshipModel>> call({
    required String studentId,
    required String department,
    required InternshipSubmissionRequest request,
  }) {
    return _repository.submitInternship(
      studentId: studentId,
      department: department,
      request: request,
    );
  }
}
