import 'package:flutter/widgets.dart';

/// Scales and offsets [child] (typically an avatar) from [expandedSize] down
/// to [collapsedSize] as collapse progress `t` moves from `1.0` to `0.0`, and
/// shifts it toward [collapsedAlignment] so it can dock into a compact nav
/// bar slot.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class AvatarCollapseEffect extends StatelessWidget {
  const AvatarCollapseEffect({
    required this.t,
    required this.expandedSize,
    required this.collapsedSize,
    required this.child,
    super.key,
    this.expandedAlignment = Alignment.center,
    this.collapsedAlignment = Alignment.centerLeft,
  });

  /// Collapse progress: `1.0` fully expanded, `0.0` fully collapsed.
  final double t;

  final double expandedSize;
  final double collapsedSize;
  final Alignment expandedAlignment;
  final Alignment collapsedAlignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = Tween<double>(
      begin: collapsedSize,
      end: expandedSize,
    ).transform(t);
    final alignment =
        Alignment.lerp(collapsedAlignment, expandedAlignment, t) ??
        expandedAlignment;

    return Align(
      alignment: alignment,
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
