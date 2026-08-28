import '../../data/models/logbook_entry_model.dart';

/// UI state for the student logbook workflow.
class LogbookState {
  /// Creates logbook UI state.
  const LogbookState({
    this.today,
    this.history = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Today's entry, if one has been submitted.
  final LogbookEntryModel? today;

  /// Recent entries, most recent first.
  final List<LogbookEntryModel> history;

  /// Whether a submission is currently being saved.
  final bool isSubmitting;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Returns a copy with selected fields changed.
  LogbookState copyWith({
    LogbookEntryModel? today,
    List<LogbookEntryModel>? history,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return LogbookState(
      today: today ?? this.today,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}
