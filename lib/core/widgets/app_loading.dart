import 'package:flutter/material.dart';

import 'skeleton.dart';

/// What kind of content is loading, so the placeholder matches its shape.
enum AppLoadingLayout {
  /// A list of rows.
  list,

  /// A dashboard: stat tiles and sections.
  dashboard,

  /// A single record's detail page.
  detail,
}

/// Loading state for a whole screen or tab: a shimmering placeholder in the
/// shape of the content, rather than a bare spinner.
class AppLoading extends StatelessWidget {
  /// Creates a loading placeholder.
  const AppLoading({
    this.message,
    this.layout = AppLoadingLayout.list,
    super.key,
  });

  /// Announced to screen readers; not shown.
  final String? message;

  /// Placeholder shape.
  final AppLoadingLayout layout;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      child: switch (layout) {
        AppLoadingLayout.list => const SkeletonList(),
        AppLoadingLayout.dashboard => const SkeletonDashboard(),
        AppLoadingLayout.detail => const SkeletonDetail(),
      },
    );
  }
}
