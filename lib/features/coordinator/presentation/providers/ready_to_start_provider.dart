import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';

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

  Future<Result<void>> activate(String internshipId) async {
    final repository = ref.read(internshipRepositoryProvider);
    final result = await repository.activateInternship(internshipId);

    if (result is Success<void>) {
      ref.invalidateSelf(); // triggers build() to run again, refreshing the list
    }
    return result;
  }
}

final readyToStartProvider =
    AsyncNotifierProvider<ReadyToStartController, List<InternshipModel>>(
      ReadyToStartController.new,
    );
