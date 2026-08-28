import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';

/// Provides recent attendance records across the signed-in lecturer's
/// assigned students.
final lecturerAttendanceProvider = FutureProvider<List<AttendanceModel>>((
  ref,
) async {
  final sessionValue = ref.watch(authSessionProvider);
  final lecturerId = switch (sessionValue) {
    AsyncData(:final value) => value.firebaseUser?.uid,
    _ => null,
  };
  if (lecturerId == null) {
    return const [];
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  final result = await repository.getAttendanceForLecturer(lecturerId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
