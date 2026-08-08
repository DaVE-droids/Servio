import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/attendance_repository.dart';
import '../../data/services/attendance_service.dart';
import '../../domain/use_cases/check_in_use_case.dart';
import '../controllers/attendance_controller.dart';

/// Provides the attendance service placeholder.
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return const AttendanceService();
});

/// Provides the attendance repository placeholder.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return const AttendanceRepository();
});

/// Provides the check-in use case placeholder.
final checkInUseCaseProvider = Provider<CheckInUseCase>((ref) {
  return CheckInUseCase(ref.watch(attendanceRepositoryProvider));
});

/// Provides the attendance controller placeholder.
final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, void>(AttendanceController.new);
