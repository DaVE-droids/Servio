import 'package:flutter/animation.dart';

/// Motion timing tokens defined by the Servio Design System.
abstract final class AppDurations {
  /// Button feedback timing.
  static const buttonFeedback = Duration(milliseconds: 120);

  /// Page transition timing.
  static const pageTransition = Duration(milliseconds: 280);

  /// Bottom sheet presentation timing.
  static const bottomSheet = Duration(milliseconds: 280);

  /// Dialog presentation timing.
  static const dialog = Duration(milliseconds: 220);

  /// Snackbar presentation timing.
  static const snackbar = Duration(milliseconds: 220);

  /// Standard easing curve for app motion.
  static const Curve curve = Curves.easeInOut;
}
