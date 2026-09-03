/// Mutable UI state for authentication forms and actions.
class AuthenticationState {
  /// Creates authentication UI state.
  const AuthenticationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Whether an authentication action is running.
  final bool isLoading;

  /// Last user-facing error message.
  final String? errorMessage;

  /// Last user-facing success message.
  final String? successMessage;

  /// Returns a copy with selected fields changed.
  AuthenticationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AuthenticationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}
