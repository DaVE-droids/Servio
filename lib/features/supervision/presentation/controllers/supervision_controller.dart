import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../../core/result/result.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/supervision_report_model.dart';
import '../../data/models/supervision_report_request.dart';
import '../providers/supervision_providers.dart';
import 'supervision_report_state.dart';

/// Controller for the lecturer visit report submission form.
class SupervisionController extends Notifier<SupervisionReportState> {
  /// Builds the initial supervision report form state.
  @override
  SupervisionReportState build() => const SupervisionReportState();

  /// Submits a visit report for the given internship. [studentName] and
  /// [studentMatricNumber] come from the student's profile, already loaded
  /// by the calling screen for display (FR-SUP-002), so this doesn't
  /// re-fetch it.
  Future<SupervisionReportModel?> submit({
    required InternshipModel internship,
    required String studentName,
    required String studentMatricNumber,
    required SupervisionReportRequest request,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);

    final lecturer = switch (ref.read(profileControllerProvider)) {
      AsyncData(:final value) => value.user,
      _ => null,
    };
    if (lecturer == null) {
      state = state.copyWith(
        isSubmitting: false,
        clearMessages: true,
        errorMessage:
            'Your profile could not be loaded. Please refresh and try again.',
      );
      return null;
    }

    final result = await ref
        .read(createSupervisionReportUseCaseProvider)
        .call(
          lecturerId: lecturer.uid,
          lecturerName: '${lecturer.firstName} ${lecturer.lastName}',
          studentId: internship.studentId,
          studentName: studentName,
          studentMatricNumber: studentMatricNumber,
          companyName: internship.companyName,
          state: internship.state,
          request: request,
        );

    switch (result) {
      case Success<SupervisionReportModel>(:final data):
        // Refreshes both the student's visit history and the assigned
        // students list's "last visited" indicators.
        ref
          ..invalidate(lecturerReportsProvider)
          ..invalidate(internshipProgressProvider);
        state = state.copyWith(
          isSubmitting: false,
          clearMessages: true,
          successMessage: 'Visit report submitted.',
        );
        return data;
      case Failure<SupervisionReportModel>(:final error):
        state = state.copyWith(
          isSubmitting: false,
          clearMessages: true,
          errorMessage: error.message,
        );
        return null;
    }
  }
}
