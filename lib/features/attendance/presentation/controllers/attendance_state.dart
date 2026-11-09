import '../../../../core/services/location_service.dart';
import '../../data/models/attendance_model.dart';

/// UI state for the student attendance workflow.
class AttendanceState {
  /// Creates attendance UI state.
  const AttendanceState({
    this.today,
    this.history = const [],
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
    this.locationNotice,
  });

  /// Today's attendance record, if checked in.
  final AttendanceModel? today;

  /// Recent attendance history, most recent first.
  final List<AttendanceModel> history;

  /// Whether a check-in/check-out is currently being saved.
  final bool isProcessing;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Set when a check-in was held back because the phone's location could
  /// not be read. Not an error — the student is being shown what is wrong
  /// and offered the choice to fix it or check in without confirmation.
  final LocationUnavailable? locationNotice;

  /// Returns a copy with selected fields changed.
  AttendanceState copyWith({
    AttendanceModel? today,
    List<AttendanceModel>? history,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    LocationUnavailable? locationNotice,
    bool clearMessages = false,
  }) {
    return AttendanceState(
      today: today ?? this.today,
      history: history ?? this.history,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
      locationNotice:
          locationNotice ?? (clearMessages ? null : this.locationNotice),
    );
  }
}
