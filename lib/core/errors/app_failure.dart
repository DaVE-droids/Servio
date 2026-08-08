/// Categories used to map technical errors to user-facing failures.
enum FailureType {
  /// Input validation failed.
  validation,

  /// Authentication failed.
  authentication,

  /// Authorization failed.
  authorization,

  /// Network connectivity failed.
  network,

  /// Database operation failed.
  database,

  /// Storage operation failed.
  storage,

  /// Unexpected failure.
  unknown,
}

/// Domain-friendly error object returned by repositories and use cases.
class AppFailure {
  /// Creates an application failure.
  const AppFailure({
    required this.message,
    this.type = FailureType.unknown,
    this.code,
    this.technicalDetails,
  });

  /// User-facing failure message.
  final String message;

  /// Machine-readable failure category.
  final FailureType type;

  /// Optional backend or validation code.
  final String? code;

  /// Optional diagnostic details for development logging.
  final Object? technicalDetails;
}
