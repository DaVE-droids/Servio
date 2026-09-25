import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// A small heading that separates groups within a screen, with an optional
/// action on the right ("View all").
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader(this.title, {this.trailing, super.key});

  /// Heading text.
  final String title;

  /// Optional action.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
