import 'package:flutter/widgets.dart';

/// Shifts [child] vertically by a fraction of the collapse distance,
/// producing a parallax effect for header background content (e.g. a cover
/// image that scrolls slower than the sheet in front of it).
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class ParallaxEffect extends StatelessWidget {
  const ParallaxEffect({
    required this.t,
    required this.extent,
    required this.child,
    super.key,
    this.speed = 0.5,
  });

  /// Collapse progress: `1.0` fully expanded, `0.0` fully collapsed.
  final double t;

  /// Total scrollable distance the effect is applied over.
  final double extent;

  /// Fraction of [extent] the child travels relative to the scroll — `0`
  /// pins the child in place, `1` scrolls it at the same speed as content.
  final double speed;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrolled = (1 - t) * extent;
    return Transform.translate(
      offset: Offset(0, scrolled * speed),
      child: child,
    );
  }
}
