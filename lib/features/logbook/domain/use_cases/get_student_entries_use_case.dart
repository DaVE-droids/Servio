import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/repositories/logbook_repository.dart';

/// Retrieves recent logbook entries for a student.
class GetStudentEntriesUseCase {
  /// Creates a get-student-entries use case.
  const GetStudentEntriesUseCase(this._repository);

  final LogbookRepository _repository;

  /// Executes the lookup.
  Future<Result<List<LogbookEntryModel>>> call(String studentId) {
    return _repository.getStudentEntries(studentId);
  }
}
