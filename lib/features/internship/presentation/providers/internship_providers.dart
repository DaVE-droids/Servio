import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/internship_repository.dart';
import '../../data/services/internship_service.dart';
import '../../domain/use_cases/submit_internship_use_case.dart';
import '../controllers/internship_controller.dart';

/// Provides the internship service placeholder.
final internshipServiceProvider = Provider<InternshipService>((ref) {
  return const InternshipService();
});

/// Provides the internship repository placeholder.
final internshipRepositoryProvider = Provider<InternshipRepository>((ref) {
  return const InternshipRepository();
});

/// Provides the submit internship use case placeholder.
final submitInternshipUseCaseProvider = Provider<SubmitInternshipUseCase>((
  ref,
) {
  return SubmitInternshipUseCase(ref.watch(internshipRepositoryProvider));
});

/// Provides the internship controller placeholder.
final internshipControllerProvider =
    AsyncNotifierProvider<InternshipController, void>(InternshipController.new);
