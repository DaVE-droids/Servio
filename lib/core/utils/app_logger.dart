import 'package:flutter/foundation.dart';

/// Centralized logging abstraction for development diagnostics.
abstract final class AppLogger {
  /// Logs a debug message in development builds.
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Logs an error message in development builds.
  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('$message${error == null ? '' : ': $error'}');
    }
  }
}
