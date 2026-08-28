import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/logbook_repository.dart';
import '../../data/services/logbook_service.dart';
import '../../domain/use_cases/get_pending_reviews_use_case.dart';
import '../../domain/use_cases/get_student_entries_use_case.dart';
import '../../domain/use_cases/get_today_entry_use_case.dart';
import '../../domain/use_cases/review_logbook_entry_use_case.dart';
import '../../domain/use_cases/submit_logbook_use_case.dart';
import '../controllers/logbook_controller.dart';
import '../controllers/logbook_state.dart';

/// Provides the logbook Firebase service.
final logbookServiceProvider = Provider<LogbookService>((ref) {
  return LogbookService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the logbook repository.
final logbookRepositoryProvider = Provider<LogbookRepository>((ref) {
  return LogbookRepository(ref.watch(logbookServiceProvider));
});

/// Provides the submit logbook use case.
final submitLogbookUseCaseProvider = Provider<SubmitLogbookUseCase>((ref) {
  return SubmitLogbookUseCase(ref.watch(logbookRepositoryProvider));
});

/// Provides the get-today-entry use case.
final getTodayEntryUseCaseProvider = Provider<GetTodayEntryUseCase>((ref) {
  return GetTodayEntryUseCase(ref.watch(logbookRepositoryProvider));
});

/// Provides the get-student-entries use case.
final getStudentEntriesUseCaseProvider = Provider<GetStudentEntriesUseCase>((
  ref,
) {
  return GetStudentEntriesUseCase(ref.watch(logbookRepositoryProvider));
});

/// Provides the get-pending-reviews use case.
final getPendingReviewsUseCaseProvider = Provider<GetPendingReviewsUseCase>((
  ref,
) {
  return GetPendingReviewsUseCase(ref.watch(logbookRepositoryProvider));
});

/// Provides the review logbook entry use case.
final reviewLogbookEntryUseCaseProvider = Provider<ReviewLogbookEntryUseCase>(
  (ref) {
    return ReviewLogbookEntryUseCase(ref.watch(logbookRepositoryProvider));
  },
);

/// Provides the logbook controller.
final logbookControllerProvider =
    AsyncNotifierProvider<LogbookController, LogbookState>(
      LogbookController.new,
    );
