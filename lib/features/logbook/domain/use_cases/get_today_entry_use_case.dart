import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/repositories/logbook_repository.dart';

/// Retrieves today's logbook entry for an internship, if any.
class GetTodayEntryUseCase {
  /// Creates a get-today-entry use case.
  const GetTodayEntryUseCase(this._repository);

  final LogbookRepository _repository;

  /// Executes the lookup.
  Future<Result<LogbookEntryModel?>> call(String internshipId) {
    return _repository.getTodayEntry(internshipId);
  }
}
