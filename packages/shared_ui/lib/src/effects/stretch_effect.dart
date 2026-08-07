import 'package:flutter/widgets.dart';

/// Grows [child] beyond its natural [baseHeight] in response to overscroll,
/// producing the "stretch on pull-down" effect common on hero headers.
///
/// [overscroll] should be the positive overscroll distance (e.g. from an
/// [OverscrollNotification] or a negative [ScrollController.offset]) — pass
/// `0` when not overscrolling.
///
/// Generic scroll-effect utility — not tied to any specific header or page.
class StretchEffect extends StatelessWidget {
  const StretchEffect({
    required this.overscroll,
    required this.baseHeight,
    required this.child,
    super.key,
    this.maxStretch = 80,
  });

  final double overscroll;
  final double baseHeight;
  final double maxStretch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stretch = overscroll.clamp(0.0, maxStretch);

    return SizedBox(
      height: baseHeight + stretch,
      child: OverflowBox(
        maxHeight: baseHeight + stretch,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}
