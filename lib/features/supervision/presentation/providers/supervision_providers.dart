import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../data/models/supervision_report_model.dart';
import '../../data/repositories/supervision_repository.dart';
import '../../data/services/supervision_service.dart';
import '../../domain/use_cases/create_supervision_report_use_case.dart';
import '../../domain/use_cases/get_reports_use_case.dart';
import '../controllers/supervision_controller.dart';
import '../controllers/supervision_report_state.dart';

/// Provides the supervision Firebase service.
final supervisionServiceProvider = Provider<SupervisionService>((ref) {
  return SupervisionService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the supervision repository.
final supervisionRepositoryProvider = Provider<SupervisionRepository>((ref) {
  return SupervisionRepository(ref.watch(supervisionServiceProvider));
});

/// Provides the create supervision report use case.
final createSupervisionReportUseCaseProvider =
    Provider<CreateSupervisionReportUseCase>((ref) {
      return CreateSupervisionReportUseCase(
        ref.watch(supervisionRepositoryProvider),
      );
    });

/// Provides the get reports use case.
final getReportsUseCaseProvider = Provider<GetReportsUseCase>((ref) {
  return GetReportsUseCase(ref.watch(supervisionRepositoryProvider));
});

/// Every visit report the signed-in lecturer has submitted, most recent
/// first.
///
/// Loaded once and shared: the assigned-students list derives each card's
/// "last visited" indicator from it, and each student detail screen filters
/// it by internship for that student's visit history. Invalidate it after
/// submitting a report so both views update.
final lecturerReportsProvider = FutureProvider<List<SupervisionReportModel>>((
  ref,
) async {
  final uid = switch (ref.watch(authSessionProvider)) {
    AsyncData(:final value) => value.firebaseUser?.uid,
    _ => null,
  };
  if (uid == null) {
    return const [];
  }
  final result = await ref.watch(getReportsUseCaseProvider).call(uid);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// The most recent visit per internship, keyed by internship ID.
final lastVisitByInternshipProvider =
    Provider<AsyncValue<Map<String, DateTime>>>((ref) {
      return ref.watch(lecturerReportsProvider).whenData((reports) {
        final lastVisits = <String, DateTime>{};
        // Reports arrive most-recent-first, so the first one seen for an
        // internship is its latest visit.
        for (final report in reports) {
          lastVisits.putIfAbsent(report.internshipId, () => report.visitDate);
        }
        return lastVisits;
      });
    });

/// Provides the supervision visit report form controller.
final supervisionControllerProvider =
    NotifierProvider<SupervisionController, SupervisionReportState>(
      SupervisionController.new,
    );
