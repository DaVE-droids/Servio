import '../../data/models/internship_model.dart';

/// UI state for the student internship placement workflow.
class InternshipState {
  /// Creates internship UI state.
  const InternshipState({
    this.currentInternship,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.lastLoadedAt,
  });

  /// Current student internship, if one exists.
  final InternshipModel? currentInternship;

  /// Whether a submission is currently being saved.
  final bool isSubmitting;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Last successful refresh timestamp.
  final DateTime? lastLoadedAt;

  /// Returns a copy with selected fields changed.
  InternshipState copyWith({
    InternshipModel? currentInternship,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    DateTime? lastLoadedAt,
    bool clearMessages = false,
  }) {
    return InternshipState(
      currentInternship: currentInternship ?? this.currentInternship,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}
