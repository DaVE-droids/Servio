/// Date and time helpers shared across features.
abstract final class DateTimeHelper {
  /// Returns the current UTC timestamp for model placeholders.
  static DateTime nowUtc() => DateTime.now().toUtc();
}
