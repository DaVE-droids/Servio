import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/logbook_repository.dart';
import '../../data/services/logbook_service.dart';
import '../../domain/use_cases/submit_logbook_use_case.dart';
import '../controllers/logbook_controller.dart';

/// Provides the logbook service placeholder.
final logbookServiceProvider = Provider<LogbookService>((ref) {
  return const LogbookService();
});

/// Provides the logbook repository placeholder.
final logbookRepositoryProvider = Provider<LogbookRepository>((ref) {
  return const LogbookRepository();
});

/// Provides the submit logbook use case placeholder.
final submitLogbookUseCaseProvider = Provider<SubmitLogbookUseCase>((ref) {
  return SubmitLogbookUseCase(ref.watch(logbookRepositoryProvider));
});

/// Provides the logbook controller placeholder.
final logbookControllerProvider =
    AsyncNotifierProvider<LogbookController, void>(LogbookController.new);
