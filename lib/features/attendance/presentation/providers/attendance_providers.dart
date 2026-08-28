import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/services/attendance_service.dart';
import '../../domain/use_cases/check_in_use_case.dart';
import '../../domain/use_cases/check_out_use_case.dart';
import '../../domain/use_cases/get_attendance_history_use_case.dart';
import '../../domain/use_cases/get_today_attendance_use_case.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/attendance_state.dart';

/// Provides the attendance Firebase service.
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the attendance repository.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(attendanceServiceProvider));
});

/// Provides the check-in use case.
final checkInUseCaseProvider = Provider<CheckInUseCase>((ref) {
  return CheckInUseCase(ref.watch(attendanceRepositoryProvider));
});

/// Provides the check-out use case.
final checkOutUseCaseProvider = Provider<CheckOutUseCase>((ref) {
  return CheckOutUseCase(ref.watch(attendanceRepositoryProvider));
});

/// Provides the get-today-attendance use case.
final getTodayAttendanceUseCaseProvider = Provider<GetTodayAttendanceUseCase>((
  ref,
) {
  return GetTodayAttendanceUseCase(ref.watch(attendanceRepositoryProvider));
});

/// Provides the get-attendance-history use case.
final getAttendanceHistoryUseCaseProvider =
    Provider<GetAttendanceHistoryUseCase>((ref) {
      return GetAttendanceHistoryUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

/// Provides the attendance controller.
final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, AttendanceState>(
      AttendanceController.new,
    );
