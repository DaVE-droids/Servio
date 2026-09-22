import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import 'coordinator_identity.dart';
import 'coordinator_overview_provider.dart';

/// Manages internships that have a lecturer assigned but haven't started
/// yet (status `assigned`, awaiting activation to `active`).
class ReadyToStartController extends AsyncNotifier<List<InternshipModel>> {
  @override
  Future<List<InternshipModel>> build() async {
    final repository = ref.watch(internshipRepositoryProvider);
    final result = await repository.getReadyToStartInternships();

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<Result<void>> activate(
    InternshipModel internship,
    String coordinatorId,
  ) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.activateInternship(
      internship: internship,
      coordinatorId: coordinatorId,
      coordinatorName: await _coordinatorName(),
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
      // Students, Lecturers, and Reports read the shared overview.
      ref.invalidate(coordinatorOverviewProvider);
    }
    return result;
  }

  /// The signed-in coordinator's display name, denormalized onto the audit
  /// event so the trail names who acted without a second lookup.
  Future<String> _coordinatorName() async =>
      (await readCoordinatorIdentity(ref))?.name ?? 'A coordinator';
}

final readyToStartProvider =
    AsyncNotifierProvider<ReadyToStartController, List<InternshipModel>>(
      ReadyToStartController.new,
    );
