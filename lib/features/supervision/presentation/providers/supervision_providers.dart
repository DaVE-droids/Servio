import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervision_repository.dart';
import '../../data/services/supervision_service.dart';
import '../../domain/use_cases/create_supervision_report_use_case.dart';
import '../controllers/supervision_controller.dart';

/// Provides the supervision service placeholder.
final supervisionServiceProvider = Provider<SupervisionService>((ref) {
  return const SupervisionService();
});

/// Provides the supervision repository placeholder.
final supervisionRepositoryProvider = Provider<SupervisionRepository>((ref) {
  return const SupervisionRepository();
});

/// Provides the create supervision report use case placeholder.
final createSupervisionReportUseCaseProvider =
    Provider<CreateSupervisionReportUseCase>((ref) {
      return CreateSupervisionReportUseCase(
        ref.watch(supervisionRepositoryProvider),
      );
    });

/// Provides the supervision controller placeholder.
final supervisionControllerProvider =
    AsyncNotifierProvider<SupervisionController, void>(
      SupervisionController.new,
    );
