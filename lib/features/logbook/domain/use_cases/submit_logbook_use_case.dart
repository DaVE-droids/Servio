import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/repositories/logbook_repository.dart';

/// Use case placeholder for digital logbook submission.
class SubmitLogbookUseCase {
  /// Creates a submit logbook use case.
  const SubmitLogbookUseCase(this._repository);

  final LogbookRepository _repository;

  /// Executes the placeholder submission workflow.
  Future<Result<List<LogbookEntryModel>>> call() =>
      _repository.getStudentEntries();
}
