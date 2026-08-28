import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';

/// Placeholder screen for student destinations that are not implemented yet.
class StudentComingSoonScreen extends StatelessWidget {
  /// Creates a student coming-soon screen.
  const StudentComingSoonScreen({
    required this.title,
    required this.message,
    super.key,
  });

  /// Screen title.
  final String title;

  /// Placeholder explanation.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppEmptyState(title: title, message: message),
    );
  }
}
