import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import 'approved_internships_provider.dart';
import 'coordinator_identity.dart';
import 'coordinator_overview_provider.dart';

class PendingInternshipsController extends AsyncNotifier<List<InternshipModel>> {
  @override
  Future<List<InternshipModel>> build() async {
    final repository = ref.watch(internshipRepositoryProvider);
    final result = await repository.getPendingInternships();

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<Result<void>> approve(
    InternshipModel internship,
    String coordinatorId,
  ) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.approveInternship(
      internship: internship,
      coordinatorId: coordinatorId,
      coordinatorName: await _coordinatorName(),
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
      // Approving moves the placement into the "needs lecturer" bucket, so
      // that list — a separate provider, fetched independently — needs to
      // pick it up too, not just this one.
      ref.invalidate(approvedInternshipsProvider);
      // Students, Lecturers, and Reports read the shared overview.
      ref.invalidate(coordinatorOverviewProvider);
    }
    return result;
  }

  Future<Result<void>> reject(
    InternshipModel internship,
    String coordinatorId,
  ) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.rejectInternship(
      internship: internship,
      coordinatorId: coordinatorId,
      coordinatorName: await _coordinatorName(),
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
      ref.invalidate(coordinatorOverviewProvider);
    }
    return result;
  }

  /// The signed-in coordinator's display name, denormalized onto the
  /// notifications and audit events they trigger so both name who acted.
  Future<String> _coordinatorName() async =>
      (await readCoordinatorIdentity(ref))?.name ?? 'A coordinator';
}

final pendingInternshipsProvider =
AsyncNotifierProvider<PendingInternshipsController, List<InternshipModel>>(
  PendingInternshipsController.new,
);