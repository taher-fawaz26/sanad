import 'package:flutter/widgets.dart';
import 'package:shared_ui/src/extensions/scroll_collapse_extensions.dart';

/// Rebuilds [builder] with a `1.0` (expanded) → `0.0` (collapsed) progress
/// value derived from [scrollController]'s offset over [collapseRange].
///
/// A thin [AnimatedBuilder] wrapper around [scrollCollapseProgress] so
/// scroll-driven headers/effects don't each re-implement the same
/// listenable + derive-value boilerplate.
class CollapseProgressBuilder extends StatelessWidget {
  const CollapseProgressBuilder({
    required this.scrollController,
    required this.collapseRange,
    required this.builder,
    super.key,
    this.child,
  });

  final ScrollController scrollController;
  final double collapseRange;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) => builder(
        context,
        scrollController.collapseProgress(collapseRange),
        child,
      ),
      child: child,
    );
  }
}
