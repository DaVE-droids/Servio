/// UI state for the lecturer visit report submission form.
class SupervisionReportState {
  /// Creates supervision report UI state.
  const SupervisionReportState({
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Whether a submission is currently being saved.
  final bool isSubmitting;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Returns a copy with selected fields changed.
  ///
  /// [clearMessages] drops any message carried over from a previous action,
  /// but a message passed explicitly here still wins — otherwise setting a
  /// new message and clearing stale ones in the same call would silently
  /// discard the new one, and the snackbar would never fire.
  SupervisionReportState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SupervisionReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}
