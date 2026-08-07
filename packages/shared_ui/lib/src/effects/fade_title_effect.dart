import 'package:flutter/widgets.dart';

/// Fades [child] in as collapse progress `t` moves from [threshold] to `0.0`
/// (i.e. as the header collapses). At `t >= threshold` the child is fully
/// transparent; at `t == 0` it is fully opaque.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class FadeTitleEffect extends StatelessWidget {
  const FadeTitleEffect({
    required this.t,
    required this.child,
    super.key,
    this.threshold = 0.5,
  });

  /// Collapse progress: `1.0` fully expanded, `0.0` fully collapsed.
  final double t;

  /// Progress value above which [child] is fully hidden.
  final double threshold;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = threshold <= 0
        ? (t <= 0 ? 1.0 : 0.0)
        : (1 - (t.clamp(0.0, threshold) / threshold));

    return Opacity(opacity: opacity, child: child);
  }
}
