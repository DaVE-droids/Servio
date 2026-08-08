import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reports_repository.dart';
import '../../data/services/reports_service.dart';
import '../../domain/use_cases/load_reports_use_case.dart';
import '../controllers/reports_controller.dart';

/// Provides the reports service placeholder.
final reportsServiceProvider = Provider<ReportsService>((ref) {
  return const ReportsService();
});

/// Provides the reports repository placeholder.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return const ReportsRepository();
});

/// Provides the load reports use case placeholder.
final loadReportsUseCaseProvider = Provider<LoadReportsUseCase>((ref) {
  return LoadReportsUseCase(ref.watch(reportsRepositoryProvider));
});

/// Provides the reports controller placeholder.
final reportsControllerProvider =
    AsyncNotifierProvider<ReportsController, void>(ReportsController.new);
