import 'package:flutter/widgets.dart';

/// Crossfades a nav bar's background between [expandedColor] (typically
/// transparent, over a hero image) and [collapsedColor] (a solid surface
/// color) as collapse progress `t` moves from `1.0` to `0.0`.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class NavSurfaceTransitionEffect extends StatelessWidget {
  const NavSurfaceTransitionEffect({
    required this.t,
    required this.expandedColor,
    required this.collapsedColor,
    required this.child,
    super.key,
  });

  /// Collapse progress: `1.0` fully expanded, `0.0` fully collapsed.
  final double t;

  final Color expandedColor;
  final Color collapsedColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color =
        Color.lerp(collapsedColor, expandedColor, t.clamp(0.0, 1.0)) ??
        collapsedColor;

    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: child,
    );
  }
}
