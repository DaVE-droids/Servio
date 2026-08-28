import '../../../../core/result/result.dart';
import '../../data/models/internship_model.dart';
import '../../data/repositories/internship_repository.dart';

/// Use case for loading the authenticated student's current internship.
class GetCurrentInternshipUseCase {
  /// Creates a current internship use case.
  const GetCurrentInternshipUseCase(this._repository);

  final InternshipRepository _repository;

  /// Loads the current internship for a student.
  Future<Result<InternshipModel?>> call(String studentId) {
    return _repository.getCurrentInternship(studentId);
  }
}
