import '../errors/app_failure.dart';

/// Standard success-or-failure wrapper for asynchronous application work.
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Returns true when this result contains a success value.
  bool get isSuccess => this is Success<T>;

  /// Returns true when this result contains a failure.
  bool get isFailure => this is Failure<T>;
}

/// Successful result containing data.
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.data);

  /// Successful data.
  final T data;
}

/// Failed result containing an application failure.
final class Failure<T> extends Result<T> {
  /// Creates a failed result.
  const Failure(this.error);

  /// Failure details.
  final AppFailure error;
}
