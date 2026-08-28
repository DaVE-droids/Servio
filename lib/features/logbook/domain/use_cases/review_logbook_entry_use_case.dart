import '../../../../core/result/result.dart';
import '../../data/repositories/logbook_repository.dart';

/// Lecturer review actions on a submitted logbook entry.
class ReviewLogbookEntryUseCase {
  /// Creates a review logbook entry use case.
  const ReviewLogbookEntryUseCase(this._repository);

  final LogbookRepository _repository;

  /// Approves the entry, locking it.
  Future<Result<void>> approve(String entryId) {
    return _repository.approveEntry(entryId);
  }

  /// Requests changes, keeping the entry editable.
  Future<Result<void>> requestChanges({
    required String entryId,
    required String comments,
  }) {
    return _repository.requestChanges(entryId: entryId, comments: comments);
  }
}
