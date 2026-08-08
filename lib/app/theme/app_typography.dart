import 'package:flutter/material.dart';

/// Typography tokens defined by the Servio Design System.
abstract final class AppTypography {
  /// Shared font family preference for Servio.
  static const String fontFamily = 'Inter';

  /// Text theme using the documented type scale.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  );
}
