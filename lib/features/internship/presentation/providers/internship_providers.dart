import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/internship_repository.dart';
import '../../data/services/internship_service.dart';
import '../../domain/use_cases/get_current_internship_use_case.dart';
import '../../domain/use_cases/submit_internship_use_case.dart';
import '../controllers/internship_controller.dart';
import '../controllers/internship_state.dart';

/// Provides the internship Firebase service.
final internshipServiceProvider = Provider<InternshipService>((ref) {
  return InternshipService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the internship repository.
final internshipRepositoryProvider = Provider<InternshipRepository>((ref) {
  return InternshipRepository(ref.watch(internshipServiceProvider));
});

/// Provides the current internship use case.
final getCurrentInternshipUseCaseProvider =
    Provider<GetCurrentInternshipUseCase>((ref) {
      return GetCurrentInternshipUseCase(
        ref.watch(internshipRepositoryProvider),
      );
    });

/// Provides the submit internship use case.
final submitInternshipUseCaseProvider = Provider<SubmitInternshipUseCase>((
  ref,
) {
  return SubmitInternshipUseCase(
    ref.watch(internshipRepositoryProvider),
    ref.watch(mapsServiceProvider),
  );
});

/// Provides the internship controller.
final internshipControllerProvider =
    AsyncNotifierProvider<InternshipController, InternshipState>(
      InternshipController.new,
    );
