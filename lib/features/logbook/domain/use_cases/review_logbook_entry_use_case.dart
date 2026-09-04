import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/repositories/logbook_repository.dart';

/// Lecturer review actions on a submitted logbook entry.
///
/// Both actions take the whole entry rather than just its ID: reviewing
/// also notifies the student, and that notification needs the entry's
/// student, lecturer, and date — all of which the review queue already has
/// loaded, so passing them avoids re-reading the document.
class ReviewLogbookEntryUseCase {
  /// Creates a review logbook entry use case.
  const ReviewLogbookEntryUseCase(this._repository);

  final LogbookRepository _repository;

  /// Approves the entry, locking it.
  Future<Result<void>> approve(LogbookEntryModel entry) {
    return _repository.approveEntry(entry);
  }

  /// Requests changes, keeping the entry editable.
  Future<Result<void>> requestChanges({
    required LogbookEntryModel entry,
    required String comments,
  }) {
    return _repository.requestChanges(entry: entry, comments: comments);
  }
}
