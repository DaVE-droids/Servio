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

  /// Returns a copy with selected fields changed.
  AttendanceState copyWith({
    AttendanceModel? today,
    List<AttendanceModel>? history,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AttendanceState(
      today: today ?? this.today,
      history: history ?? this.history,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}
