import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Servio's placeholder mark: a route from a starting stop to a finishing
/// ring, curving into an "S" — the placement journey in one stroke.
///
/// Drawn in code so it stays crisp at any size. When the final logo
/// arrives, replace this painter (and the generated images described in
/// docs/BRANDING.md) and every screen picks it up.
class BrandMark extends StatelessWidget {
  /// Creates the brand mark.
  const BrandMark({this.size = 36, this.inverted = false, super.key});

  /// Width and height.
  final double size;

  /// White tile with an ink route, for use on dark backgrounds.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Servio',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _BrandMarkPainter(inverted: inverted),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.inverted});

  final bool inverted;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.28),
    );
    canvas.drawRRect(
      tile,
      Paint()..color = inverted ? Colors.white : AppColors.ink,
    );

    final routeColor = inverted ? AppColors.ink : Colors.white;
    final stroke = s * 0.095;
    final route = Path()
      ..moveTo(s * 0.30, s * 0.70)
      ..cubicTo(s * 0.30, s * 0.44, s * 0.70, s * 0.56, s * 0.70, s * 0.33);
    canvas.drawPath(
      route,
      Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Start: a solid stop.
    canvas.drawCircle(
      Offset(s * 0.30, s * 0.72),
      s * 0.085,
      Paint()..color = AppColors.sky,
    );
    // Finish: a ring.
    canvas.drawCircle(
      Offset(s * 0.70, s * 0.28),
      s * 0.085,
      Paint()
        ..color = AppColors.blush
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.8,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.inverted != inverted;
}

/// The mark with the "Servio" wordmark beside it.
class BrandLockup extends StatelessWidget {
  /// Creates the lockup.
  const BrandLockup({this.markSize = 34, this.onDark = false, super.key});

  /// Size of the mark; the wordmark scales with it.
  final double markSize;

  /// Light text for dark backgrounds.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize, inverted: onDark),
        SizedBox(width: markSize * 0.3),
        Text(
          'Servio',
          style: TextStyle(
            fontSize: markSize * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: onDark ? Colors.white : AppColors.inkDeep,
          ),
        ),
      ],
    );
  }
}
