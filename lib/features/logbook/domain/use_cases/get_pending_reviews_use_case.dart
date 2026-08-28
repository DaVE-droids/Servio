import '../../../../core/result/result.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/repositories/logbook_repository.dart';

/// Retrieves entries awaiting review across a lecturer's assigned
/// students.
class GetPendingReviewsUseCase {
  /// Creates a get-pending-reviews use case.
  const GetPendingReviewsUseCase(this._repository);

  final LogbookRepository _repository;

  /// Executes the lookup.
  Future<Result<List<LogbookEntryModel>>> call(String lecturerId) {
    return _repository.getPendingReviews(lecturerId);
  }
}
