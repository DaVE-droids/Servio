import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';

/// Resolves the signed-in lecturer's UID from the auth session, if any.
final _lecturerIdProvider = Provider<String?>((ref) {
  final sessionValue = ref.watch(authSessionProvider);
  return switch (sessionValue) {
    AsyncData(:final value) => value.firebaseUser?.uid,
    _ => null,
  };
});

/// Manages placements currently assigned to the signed-in lecturer.
class AssignedStudentsController extends AsyncNotifier<List<InternshipModel>> {
  @override
  Future<List<InternshipModel>> build() async {
    final lecturerId = ref.watch(_lecturerIdProvider);
    if (lecturerId == null) {
      return const [];
    }

    final repository = ref.watch(internshipRepositoryProvider);
    final result = await repository.getAssignedInternships(lecturerId);

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }
}

final assignedStudentsProvider =
    AsyncNotifierProvider<AssignedStudentsController, List<InternshipModel>>(
      AssignedStudentsController.new,
    );
