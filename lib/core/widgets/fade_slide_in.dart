import 'package:flutter/material.dart';

/// Eases its child in — a short fade and a small upward drift — when it
/// first appears. Give each section of a screen a rising [index] and they
/// arrive one after another instead of all at once.
///
/// Does nothing when the user has asked the system to reduce motion.
class FadeSlideIn extends StatefulWidget {
  /// Creates an entrance animation.
  const FadeSlideIn({required this.child, this.index = 0, super.key});

  /// Content to animate in.
  final Widget child;

  /// Position in the sequence; each step adds a short delay.
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      Duration(milliseconds: 45 * widget.index.clamp(0, 8)),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
