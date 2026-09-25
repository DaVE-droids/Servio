import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Two columns side by side on wide screens (a narrow one for identity, a
/// wide one for activity), stacked into one on phones.
///
/// Meant to sit inside a scrolling list; each column's children are laid
/// out top to bottom with a standard gap.
class ResponsiveColumns extends StatelessWidget {
  /// Creates responsive columns.
  const ResponsiveColumns({
    required this.primary,
    required this.secondary,
    this.breakpoint = 860,
    this.primaryFlex = 5,
    this.secondaryFlex = 8,
    super.key,
  });

  /// The narrow column (left on wide screens, first on phones).
  final List<Widget> primary;

  /// The wide column (right on wide screens, second on phones).
  final List<Widget> secondary;

  /// Width at which the columns sit side by side.
  final double breakpoint;

  /// Share of the width the primary column takes on wide screens.
  final int primaryFlex;

  /// Share of the width the secondary column takes on wide screens.
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return _stack([...primary, ...secondary]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: _stack(primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: secondaryFlex, child: _stack(secondary)),
          ],
        );
      },
    );
  }

  Widget _stack(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          children[i],
        ],
      ],
    );
  }
}
