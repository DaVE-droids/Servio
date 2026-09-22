import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../audit/presentation/providers/audit_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'approved_internships_provider.dart';
import 'coordinator_identity.dart';
import 'coordinator_overview_provider.dart';
import 'ready_to_start_provider.dart';

/// Coordinator actions launched from the Students and Lecturers screens.
///
/// Each one resolves who the coordinator is, performs the write, and on
/// success refreshes every list that shows the changed data — the shared
/// overview, the dashboard tabs, the lecturer picker, and the audit trail.
class CoordinatorActions {
  /// Creates the coordinator actions.
  const CoordinatorActions(this._ref);

  final Ref _ref;

  /// Marks an active internship completed.
  Future<Result<void>> completeInternship(InternshipModel internship) async {
    final coordinator = await readCoordinatorIdentity(_ref);
    if (coordinator == null) {
      return _sessionExpired;
    }
    final result = await _ref
        .read(internshipRepositoryProvider)
        .completeInternship(
          internship: internship,
          coordinatorId: coordinator.id,
          coordinatorName: coordinator.name,
        );
    if (result is Success<void>) {
      _refreshAll();
    }
    return result;
  }

  /// Approves (`isActive: true`) or deactivates a lecturer account.
  Future<Result<void>> setLecturerActive(
    UserModel lecturer, {
    required bool isActive,
  }) async {
    final coordinator = await readCoordinatorIdentity(_ref);
    if (coordinator == null) {
      return _sessionExpired;
    }
    final result = await _ref
        .read(profileRepositoryProvider)
        .setLecturerActive(
          lecturer: lecturer,
          isActive: isActive,
          coordinatorId: coordinator.id,
          coordinatorName: coordinator.name,
        );
    if (result is Success<void>) {
      _refreshAll();
    }
    return result;
  }

  void _refreshAll() {
    _ref
      ..invalidate(coordinatorOverviewProvider)
      ..invalidate(readyToStartProvider)
      ..invalidate(approvedInternshipsProvider)
      ..invalidate(lecturersProvider)
      ..invalidate(auditControllerProvider);
  }

  static const _sessionExpired = Failure<void>(
    AppFailure(
      message: 'Your session has expired. Please sign in again.',
      type: FailureType.authentication,
    ),
  );
}

/// Provides the coordinator actions.
final coordinatorActionsProvider = Provider<CoordinatorActions>(
  CoordinatorActions.new,
);
