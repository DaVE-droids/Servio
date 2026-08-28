import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../../logbook/presentation/providers/logbook_providers.dart';

/// Manages logbook entries awaiting the signed-in lecturer's review.
class PendingLogbookReviewsController
    extends AsyncNotifier<List<LogbookEntryModel>> {
  @override
  Future<List<LogbookEntryModel>> build() async {
    final lecturerId = _currentLecturerId();
    if (lecturerId == null) {
      return const [];
    }

    final repository = ref.watch(logbookRepositoryProvider);
    final result = await repository.getPendingReviews(lecturerId);

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// Approves an entry, locking it.
  Future<Result<void>> approve(String entryId) async {
    final result = await ref
        .read(reviewLogbookEntryUseCaseProvider)
        .approve(entryId);
    if (result is Success<void>) {
      ref.invalidateSelf();
    }
    return result;
  }

  /// Requests changes on an entry, keeping it editable.
  Future<Result<void>> requestChanges({
    required String entryId,
    required String comments,
  }) async {
    final result = await ref
        .read(reviewLogbookEntryUseCaseProvider)
        .requestChanges(entryId: entryId, comments: comments);
    if (result is Success<void>) {
      ref.invalidateSelf();
    }
    return result;
  }

  String? _currentLecturerId() {
    final sessionValue = ref.watch(authSessionProvider);
    return switch (sessionValue) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };
  }
}

final pendingLogbookReviewsProvider =
    AsyncNotifierProvider<
      PendingLogbookReviewsController,
      List<LogbookEntryModel>
    >(PendingLogbookReviewsController.new);
