import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';

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
    required String internshipId,
    required String lecturerId,
  }) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.assignLecturer(
      internshipId: internshipId,
      lecturerId: lecturerId,
    );

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
    }
    return result;
  }
}

final approvedInternshipsProvider =
    AsyncNotifierProvider<
      ApprovedInternshipsController,
      List<InternshipModel>
    >(ApprovedInternshipsController.new);
