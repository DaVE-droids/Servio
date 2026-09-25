import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';

/// Paints its [child]'s grey placeholder shapes with a slow shimmer, so a
/// loading screen already has the layout of the content that's coming.
///
/// One shimmer drives every shape underneath it, so the highlight sweeps
/// across the whole screen in one pass instead of each box pulsing alone.
class Shimmer extends StatefulWidget {
  /// Wraps placeholder shapes in a shimmer.
  const Shimmer({required this.child, super.key});

  /// Placeholder layout built from [SkeletonBox]es.
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion": show the static shapes only.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [AppColors.line, Color(0xFFF1F4F8), AppColors.line],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(t),
            ).createShader(bounds),
            child: child,
          );
        },
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
  }
}

/// A grey placeholder shape. Use inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  /// Creates a placeholder box.
  const SkeletonBox({this.width, this.height = 14, this.radius = 8, super.key});

  /// Width; fills the available width when null.
  final double? width;

  /// Height.
  final double height;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A placeholder card shaped like a list row: avatar, two lines, a pill.
class SkeletonListCard extends StatelessWidget {
  /// Creates a placeholder list card.
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 44, height: 44, radius: 13),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 230, height: 11),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          SkeletonBox(width: 72, height: 24, radius: 12),
        ],
      ),
    );
  }
}

/// A placeholder stat tile.
class SkeletonStatTile extends StatelessWidget {
  /// Creates a placeholder stat tile.
  const SkeletonStatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 56, height: 28),
              SkeletonBox(width: 36, height: 36, radius: 18),
            ],
          ),
          Spacer(),
          SkeletonBox(width: 110, height: 12),
        ],
      ),
    );
  }
}

/// A placeholder section card: a title and a block of lines.
class SkeletonSectionCard extends StatelessWidget {
  /// Creates a placeholder section card.
  const SkeletonSectionCard({this.lines = 4, super.key});

  /// How many placeholder lines to show.
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 150, height: 16),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < lines; i++) ...[
            SkeletonBox(width: i.isEven ? double.infinity : 220, height: 12),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for a list screen: a few list cards.
class SkeletonList extends StatelessWidget {
  /// Creates a placeholder list.
  const SkeletonList({this.count = 6, this.header = false, super.key});

  /// Number of placeholder rows.
  final int count;

  /// Whether to show a search-field placeholder above the rows.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (header) ...[
            const SkeletonBox(height: 48, radius: AppRadii.control),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var i = 0; i < count; i++) ...[
            const SkeletonListCard(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for a dashboard: a greeting, stat tiles, and two sections.
class SkeletonDashboard extends StatelessWidget {
  /// Creates a placeholder dashboard.
  const SkeletonDashboard({this.tiles = 4, super.key});

  /// Number of stat tile placeholders.
  final int tiles;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SkeletonBox(width: 120, height: 12),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(width: 240, height: 26),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? tiles : 2;
              final width =
                  (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < tiles; i++)
                    SizedBox(width: width, child: const SkeletonStatTile()),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonSectionCard(lines: 3),
          const SizedBox(height: AppSpacing.md),
          const SkeletonSectionCard(lines: 5),
        ],
      ),
    );
  }
}

/// Placeholder for a detail page: a profile header and two sections.
class SkeletonDetail extends StatelessWidget {
  /// Creates a placeholder detail page.
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.line),
            ),
            child: const Column(
              children: [
                SkeletonBox(width: 88, height: 88, radius: 26),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 180, height: 20),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 140, height: 12),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 36),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonSectionCard(lines: 4),
          const SizedBox(height: AppSpacing.md),
          const SkeletonSectionCard(lines: 3),
        ],
      ),
    );
  }
}
