import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/attendance_check_in_request.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_providers.dart';
import 'attendance_state.dart';

/// Controller for student attendance UI state and actions.
class AttendanceController extends AsyncNotifier<AttendanceState> {
  @override
  Future<AttendanceState> build() async {
    // Deliberately `watch`, not `read` — `build()` must reactively re-run
    // once internshipControllerProvider resolves. Riverpod doesn't
    // guarantee which of two independent providers' initial async loads
    // finishes first; with `read`, if this ran before internship data was
    // ready, it would permanently see "no active internship" and never
    // re-check, even after the internship data arrived a moment later.
    final internshipValue = ref.watch(internshipControllerProvider);
    final internship = switch (internshipValue) {
      AsyncData(:final value) => value.currentInternship,
      _ => null,
    };
    if (internship == null || internship.status != InternshipStatus.active) {
      return const AttendanceState();
    }
    return _load(internship);
  }

  /// Refreshes today's attendance and history.
  Future<void> refresh() async {
    final internship = _activeInternship();
    if (internship == null) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(internship));
  }

  /// Checks the current student in for today.
  Future<void> checkIn() async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const AttendanceState(),
    };

    final internship = _activeInternship();
    if (internship == null) {
      state = AsyncData(
        previous.copyWith(
          clearMessages: true,
          errorMessage:
              'Attendance is only available for an active internship.',
        ),
      );
      return;
    }

    final profile = switch (ref.read(profileControllerProvider)) {
      AsyncData(:final value) => value.user,
      _ => null,
    };
    if (profile == null) {
      state = AsyncData(
        previous.copyWith(
          clearMessages: true,
          errorMessage:
              'Your profile could not be loaded. Please refresh and try again.',
        ),
      );
      return;
    }

    if (internship.lecturerId == null) {
      state = AsyncData(
        previous.copyWith(
          clearMessages: true,
          errorMessage:
              'Your internship does not have an assigned lecturer yet.',
        ),
      );
      return;
    }

    state = AsyncData(
      previous.copyWith(isProcessing: true, clearMessages: true),
    );

    final result = await ref
        .read(checkInUseCaseProvider)
        .call(
          AttendanceCheckInRequest(
            internshipId: internship.internshipId,
            studentId: profile.uid,
            studentName: '${profile.firstName} ${profile.lastName}',
            studentMatricNumber: profile.matricNumber ?? '',
            lecturerId: internship.lecturerId!,
            // Falls back to the ID for internships assigned before lecturerName
            // denormalization existed (Phase 1 test data) rather than blocking
            // check-in entirely over a missing display field.
            lecturerName: internship.lecturerName ?? internship.lecturerId!,
            companyName: internship.companyName,
            state: internship.state,
          ),
        );

    switch (result) {
      case Success(:final data):
        ref.invalidate(internshipProgressProvider);
        state = AsyncData(
          previous.copyWith(
            today: data,
            history: [data, ...previous.history],
            isProcessing: false,
            clearMessages: true,
            successMessage: 'Checked in successfully.',
          ),
        );
      case Failure(:final error):
        state = AsyncData(
          previous.copyWith(
            isProcessing: false,
            clearMessages: true,
            errorMessage: error.message,
          ),
        );
    }
  }

  /// Checks the current student out for today.
  Future<void> checkOut() async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const AttendanceState(),
    };

    final internship = _activeInternship();
    if (internship == null) {
      return;
    }

    state = AsyncData(
      previous.copyWith(isProcessing: true, clearMessages: true),
    );

    final result = await ref
        .read(checkOutUseCaseProvider)
        .call(
          internshipId: internship.internshipId,
          studentId: internship.studentId,
          studentName: internship.studentName,
        );

    switch (result) {
      case Success():
        ref.invalidate(internshipProgressProvider);
        state = AsyncData(
          previous.copyWith(isProcessing: false, clearMessages: true),
        );
        await refresh();
        state = switch (state) {
          AsyncData(:final value) => AsyncData(
            value.copyWith(
              clearMessages: true,
              successMessage: 'Checked out successfully.',
            ),
          ),
          _ => state,
        };
      case Failure(:final error):
        state = AsyncData(
          previous.copyWith(
            isProcessing: false,
            clearMessages: true,
            errorMessage: error.message,
          ),
        );
    }
  }

  Future<AttendanceState> _load(InternshipModel internship) async {
    final Result<AttendanceModel?> todayResult = await ref
        .read(getTodayAttendanceUseCaseProvider)
        .call(internship.internshipId);
    final Result<List<AttendanceModel>> historyResult = await ref
        .read(getAttendanceHistoryUseCaseProvider)
        .call(internship.studentId);

    AttendanceModel? today;
    String? errorMessage;
    switch (todayResult) {
      case Success<AttendanceModel?>(:final data):
        today = data;
      case Failure<AttendanceModel?>(:final error):
        errorMessage = error.message;
    }

    List<AttendanceModel> history = const [];
    switch (historyResult) {
      case Success<List<AttendanceModel>>(:final data):
        history = data;
      case Failure<List<AttendanceModel>>(:final error):
        errorMessage ??= error.message;
    }

    return AttendanceState(
      today: today,
      history: history,
      errorMessage: errorMessage,
    );
  }

  InternshipModel? _activeInternship() {
    final internshipState = switch (ref.read(internshipControllerProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final internship = internshipState?.currentInternship;
    if (internship == null || internship.status != InternshipStatus.active) {
      return null;
    }
    return internship;
  }
}
