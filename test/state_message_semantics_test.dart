import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/internship/presentation/controllers/internship_state.dart';
import 'package:servio/features/supervision/presentation/controllers/supervision_report_state.dart';

/// These states carry a "last user-facing message" that screens surface via
/// a snackbar. Two opposite bugs have shipped here: a stale message from an
/// earlier action leaking into a later one, and — after over-correcting —
/// `clearMessages` swallowing the new message so no snackbar fired at all.
/// The rule these tests pin down: clearing drops carried-over messages, but
/// a message passed explicitly in the same call always survives.
void main() {
  group('InternshipState.copyWith message semantics', () {
    test('carries messages forward by default', () {
      const state = InternshipState(errorMessage: 'stale error');
      expect(state.copyWith(isSubmitting: true).errorMessage, 'stale error');
    });

    test('clearMessages drops a carried-over message', () {
      const state = InternshipState(errorMessage: 'stale error');
      final next = state.copyWith(isSubmitting: true, clearMessages: true);
      expect(next.errorMessage, isNull);
      expect(next.successMessage, isNull);
    });

    test('an explicit message survives clearMessages in the same call', () {
      const state = InternshipState(errorMessage: 'stale error');
      final next = state.copyWith(
        clearMessages: true,
        successMessage: 'Internship placement submitted for review.',
      );
      expect(next.successMessage, 'Internship placement submitted for review.');
      expect(next.errorMessage, isNull, reason: 'stale error must not leak');
    });
  });

  group('SupervisionReportState.copyWith message semantics', () {
    test('an explicit success message survives clearMessages', () {
      const state = SupervisionReportState(errorMessage: 'stale error');
      final next = state.copyWith(
        isSubmitting: false,
        clearMessages: true,
        successMessage: 'Visit report submitted.',
      );
      expect(next.successMessage, 'Visit report submitted.');
      expect(next.errorMessage, isNull);
    });

    test('an explicit error message survives clearMessages', () {
      const state = SupervisionReportState(successMessage: 'stale success');
      final next = state.copyWith(
        isSubmitting: false,
        clearMessages: true,
        errorMessage: 'Unable to save this visit report. Please try again.',
      );
      expect(
        next.errorMessage,
        'Unable to save this visit report. Please try again.',
      );
      expect(next.successMessage, isNull);
    });
  });
}
