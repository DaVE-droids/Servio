import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import 'approved_internships_provider.dart';

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

  Future<Result<void>> approve(String internshipId, String coordinatorId) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.approveInternship(
      internshipId: internshipId,
      coordinatorId: coordinatorId,
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
      // Approving moves the placement into the "needs lecturer" bucket, so
      // that list — a separate provider, fetched independently — needs to
      // pick it up too, not just this one.
      ref.invalidate(approvedInternshipsProvider);
    }
    return result;
  }

  Future<Result<void>> reject(String internshipId, String coordinatorId) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.rejectInternship(
      internshipId: internshipId,
      coordinatorId: coordinatorId,
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
    }
    return result;
  }
}

final pendingInternshipsProvider =
AsyncNotifierProvider<PendingInternshipsController, List<InternshipModel>>(
  PendingInternshipsController.new,
);