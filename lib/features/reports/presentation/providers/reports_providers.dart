import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../data/models/internship_progress.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/services/reports_service.dart';

/// Provides the reports repository (progress counting).
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(
    ReportsService(ref.watch(firebaseFirestoreProvider)),
  );
});

/// Accurate progress counts for one internship — attendance days, logbook
/// entries (and how many are approved), and visits — for whoever is
/// looking: the student themselves, their lecturer, or a coordinator.
///
/// Counted with aggregation queries rather than by loading records, so the
/// figures stay right however long the internship runs (the record lists on
/// screen only load the most recent entries).
final internshipProgressProvider = FutureProvider.autoDispose
    .family<InternshipProgress, String>((ref, internshipId) async {
      final session = ref.watch(authSessionProvider).value;
      final uid = session?.uid;
      final result = await ref
          .watch(reportsRepositoryProvider)
          .loadScopedProgress(
            internshipId,
            studentId: session?.role == UserRole.student ? uid : null,
            lecturerId: session?.role == UserRole.lecturer ? uid : null,
          );
      return switch (result) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      };
    });
