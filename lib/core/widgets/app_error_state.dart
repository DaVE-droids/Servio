import 'package:flutter/material.dart';

import '../../app/theme/app_tone.dart';
import 'app_empty_state.dart';

/// Shown when something couldn't load. Always offers a retry when one can
/// help, and never shows a raw exception.
class AppErrorState extends StatelessWidget {
  /// Creates an error state.
  const AppErrorState({
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    super.key,
  });

  /// Heading.
  final String title;

  /// User-facing explanation.
  final String message;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: Icons.cloud_off_outlined,
      tone: AppTone.error,
      actionLabel: onRetry == null ? null : 'Try again',
      onActionPressed: onRetry,
    );
  }
}
