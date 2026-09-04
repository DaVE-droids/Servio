import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'ready_to_start_provider.dart';

/// Manages approved internships awaiting lecturer assignment.
class ApprovedInternshipsController
    extends AsyncNotifier<List<InternshipModel>> {
  @override
  Future<List<InternshipModel>> build() async {
    final repository = ref.watch(internshipRepositoryProvider);
    final result = await repository.getApprovedInternships();

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<Result<void>> assignLecturer({
    required InternshipModel internship,
    required String lecturerId,
    required String lecturerName,
  }) async {
    final repository = ref.read(internshipRepositoryProvider);
    final coordinator = switch (ref.read(profileControllerProvider)) {
      AsyncData(:final value) => value.user,
      _ => null,
    };
    final result = await repository.assignLecturer(
      internship: internship,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      coordinatorId: coordinator?.uid ?? '',
      coordinatorName: coordinator == null
          ? 'Your coordinator'
          : '${coordinator.firstName} ${coordinator.lastName}',
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
      // Assigning a lecturer moves the placement into the "ready to start"
      // bucket, so that list needs to pick it up too.
      ref.invalidate(readyToStartProvider);
    }
    return result;
  }
}

final approvedInternshipsProvider =
    AsyncNotifierProvider<
      ApprovedInternshipsController,
      List<InternshipModel>
    >(ApprovedInternshipsController.new);
