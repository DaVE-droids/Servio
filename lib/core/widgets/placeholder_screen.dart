import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'app_empty_state.dart';

/// Placeholder route screen used before business features are implemented.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder screen.
  const PlaceholderScreen({
    required this.title,
    required this.description,
    super.key,
  });

  /// Screen title.
  final String title;

  /// Short description of the future screen.
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppEmptyState(title: title, message: description),
      ),
    );
  }
}
