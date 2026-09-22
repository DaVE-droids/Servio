import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../reports/data/repositories/reports_repository.dart';
import '../../../reports/data/services/reports_service.dart';
import '../../domain/coordinator_overview.dart';

/// Provides the reports repository (progress counting).
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ReportsService(ref.watch(firebaseFirestoreProvider)));
});

/// Loads the shared [CoordinatorOverview] behind the Students, Lecturers,
/// and Reports screens.
///
/// One loader for all three keeps them consistent — a student can't show
/// as "Active" on one screen and "Assigned" on another because two loaders
/// fetched at different moments. Any coordinator action that changes this
/// data invalidates it; pull-to-refresh does the same.
final coordinatorOverviewProvider = FutureProvider<CoordinatorOverview>((
  ref,
) async {
  // Reload when a different account signs in, so one coordinator's session
  // never serves data loaded under another. `select` on the UID means the
  // hourly token refresh — which also re-emits the session — doesn't
  // trigger a full reload.
  ref.watch(
    authSessionProvider.select((session) => session.value?.firebaseUser?.uid),
  );
  final profiles = ref.watch(profileRepositoryProvider);
  final internshipRepository = ref.watch(internshipRepositoryProvider);

  // The three lists load in parallel; a record's `.wait` keeps each
  // result's own type, which a `Future.wait` list would erase.
  final (studentsResult, lecturersResult, internshipsResult) = await (
    profiles.getStudents(),
    profiles.getLecturers(),
    internshipRepository.getAllInternships(),
  ).wait;
  final students = _unwrap(studentsResult);
  final lecturers = _unwrap(lecturersResult);
  final internships = _unwrap(internshipsResult);

  final trackedIds = [
    for (final internship in internships)
      if (CoordinatorOverview.trackedStatuses.contains(internship.status))
        internship.internshipId,
  ];
  final progress = _unwrap(
    await ref.watch(reportsRepositoryProvider).loadProgress(trackedIds),
  );

  return CoordinatorOverview(
    students: students,
    lecturers: lecturers,
    internships: internships,
    progress: progress,
  );
}, retry: _retryNetworkOnly);

/// Retries only connection problems, twice, a second or two apart.
///
/// Riverpod's default retries every failure with growing delays, which
/// kept the screen on its loading spinner for ~40 seconds when a stored
/// record couldn't be read — a problem no retry can fix. A network blip is
/// worth retrying; anything else should reach the error screen right away.
Duration? _retryNetworkOnly(int retryCount, Object error) {
  final isNetwork = error is AppFailure && error.type == FailureType.network;
  return isNetwork && retryCount < 2
      ? Duration(milliseconds: 1000 * (retryCount + 1))
      : null;
}

T _unwrap<T>(Result<T> result) => switch (result) {
  Success(:final data) => data,
  Failure(:final error) => throw error,
};
