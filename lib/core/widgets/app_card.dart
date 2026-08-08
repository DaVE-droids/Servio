import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Standard Servio card for grouping related information.
class AppCard extends StatelessWidget {
  /// Creates an app card.
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
