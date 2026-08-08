import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dashboard_repository.dart';
import '../../data/services/dashboard_service.dart';
import '../../domain/use_cases/load_dashboard_use_case.dart';
import '../controllers/dashboard_controller.dart';

/// Provides the dashboard service placeholder.
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return const DashboardService();
});

/// Provides the dashboard repository placeholder.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const DashboardRepository();
});

/// Provides the load dashboard use case placeholder.
final loadDashboardUseCaseProvider = Provider<LoadDashboardUseCase>((ref) {
  return LoadDashboardUseCase(ref.watch(dashboardRepositoryProvider));
});

/// Provides the dashboard controller placeholder.
final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, void>(DashboardController.new);
