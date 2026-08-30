import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/internship_status.dart';
import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/logbook_entry_model.dart';
import '../../data/models/logbook_entry_request.dart';
import '../providers/logbook_providers.dart';
import 'logbook_state.dart';

/// Controller for student logbook UI state and actions.
class LogbookController extends AsyncNotifier<LogbookState> {
  @override
  Future<LogbookState> build() async {
    // Deliberately `watch`, not `read` -- see AttendanceController for why:
    // build() must reactively re-run once internshipControllerProvider
    // resolves, since Riverpod doesn't guarantee ordering between two
    // independent providers' initial loads.
    final internshipValue = ref.watch(internshipControllerProvider);
    final internship = switch (internshipValue) {
      AsyncData(:final value) => value.currentInternship,
      _ => null,
    };
    if (internship == null || internship.status != InternshipStatus.active) {
      return const LogbookState();
    }
    return _load(internship);
  }

  /// Refreshes today's entry and history.
  Future<void> refresh() async {
    final internship = _activeInternship();
    if (internship == null) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(internship));
  }

  /// Submits (or resubmits) today's entry.
  Future<void> submit({
    required String activities,
    required String skillsLearned,
    required String challenges,
    required String solutionsApplied,
    required num hoursWorked,
  }) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const LogbookState(),
    };

    final internship = _activeInternship();
    if (internship == null) {
      state = AsyncData(
        previous.copyWith(
          clearMessages: true,
          errorMessage: 'Logbook entries are only available for an active internship.',
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
          errorMessage: 'Your internship does not have an assigned lecturer yet.',
        ),
      );
      return;
    }

    state = AsyncData(previous.copyWith(isSubmitting: true, clearMessages: true));

    final result = await ref.read(submitLogbookUseCaseProvider).call(
      LogbookEntryRequest(
        internshipId: internship.internshipId,
        studentId: profile.uid,
        studentName: '${profile.firstName} ${profile.lastName}',
        studentMatricNumber: profile.matricNumber ?? '',
        lecturerId: internship.lecturerId!,
        // Falls back to the ID for internships assigned before
        // lecturerName denormalization existed — same reasoning as
        // AttendanceController.
        lecturerName: internship.lecturerName ?? internship.lecturerId!,
        companyName: internship.companyName,
        state: internship.state,
        activities: activities,
        skillsLearned: skillsLearned,
        challenges: challenges,
        solutionsApplied: solutionsApplied,
        hoursWorked: hoursWorked,
      ),
    );

    switch (result) {
      case Success(:final data):
        final historyWithoutToday = previous.history
            .where((entry) => entry.entryId != data.entryId)
            .toList();
        state = AsyncData(
          previous.copyWith(
            today: data,
            history: [data, ...historyWithoutToday],
            isSubmitting: false,
            clearMessages: true,
            successMessage: 'Logbook entry submitted.',
          ),
        );
      case Failure(:final error):
        state = AsyncData(
          previous.copyWith(
            isSubmitting: false,
            clearMessages: true,
            errorMessage: error.message,
          ),
        );
    }
  }

  Future<LogbookState> _load(InternshipModel internship) async {
    final Result<LogbookEntryModel?> todayResult = await ref
        .read(getTodayEntryUseCaseProvider)
        .call(internship.internshipId);
    final Result<List<LogbookEntryModel>> historyResult = await ref
        .read(getStudentEntriesUseCaseProvider)
        .call(internship.studentId);

    LogbookEntryModel? today;
    String? errorMessage;
    switch (todayResult) {
      case Success<LogbookEntryModel?>(:final data):
        today = data;
      case Failure<LogbookEntryModel?>(:final error):
        errorMessage = error.message;
    }

    List<LogbookEntryModel> history = const [];
    switch (historyResult) {
      case Success<List<LogbookEntryModel>>(:final data):
        history = data;
      case Failure<List<LogbookEntryModel>>(:final error):
        errorMessage ??= error.message;
    }

    return LogbookState(today: today, history: history, errorMessage: errorMessage);
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
