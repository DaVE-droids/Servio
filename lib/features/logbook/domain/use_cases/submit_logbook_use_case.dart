import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/models/logbook_entry_request.dart';
import '../../data/repositories/logbook_repository.dart';

/// Submits (or resubmits) today's logbook entry.
class SubmitLogbookUseCase {
  /// Creates a submit logbook use case.
  const SubmitLogbookUseCase(this._repository);

  final LogbookRepository _repository;

  /// Executes the submission workflow.
  Future<Result<LogbookEntryModel>> call(LogbookEntryRequest request) {
    return _repository.submitEntry(request);
  }
}
