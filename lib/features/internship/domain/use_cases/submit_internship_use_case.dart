import '../../../../core/result/result.dart';
import '../../data/models/internship_model.dart';
import '../../data/repositories/internship_repository.dart';

/// Use case placeholder for placement submission.
class SubmitInternshipUseCase {
  /// Creates a submit internship use case.
  const SubmitInternshipUseCase(this._repository);

  final InternshipRepository _repository;

  /// Executes the placeholder submission workflow.
  Future<Result<InternshipModel>> call() => _repository.getCurrentInternship();
}
