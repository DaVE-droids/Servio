import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_model.dart';
import '../../../../core/result/result.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/location_service.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
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
  return AttendanceRepository(
    ref.watch(attendanceServiceProvider),
    const LocationService(),
  );
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

/// One student's recent attendance, for lecturers and coordinators looking
/// at that student. Cached while any screen shows it.
final studentAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, String>((ref, studentId) async {
      final session = ref.watch(authSessionProvider).value;
      final result = await ref
          .watch(getAttendanceHistoryUseCaseProvider)
          .call(
            studentId,
            lecturerId: session?.role == UserRole.lecturer
                ? session?.uid
                : null,
          );
      return switch (result) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      };
    });
