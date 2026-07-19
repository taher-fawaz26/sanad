import 'package:flutter/material.dart';

/// A scrollable that fills the remaining viewport space without performing
/// intrinsic height calculations.
///
/// ### Problem it solves
///
/// [SliverFillRemaining] with `hasScrollBody: false` calls
/// `getMaxIntrinsicHeight` on its child subtree. Any widget that uses
/// [LayoutBuilder] internally (such as `AppEmptyState`) cannot participate in
/// intrinsic sizing and will throw:
///
/// > LayoutBuilder does not support returning intrinsic dimensions.
///
/// ### Solution
///
/// This widget uses [SliverLayoutBuilder] to read `remainingPaintExtent`
/// directly from the sliver protocol — no intrinsic query is ever issued.
/// [SliverToBoxAdapter] lays out its child with tight box constraints, and
/// [ConstrainedBox] with `minHeight: remainingPaintExtent` ensures the child
/// fills the remaining viewport height.
///
/// ### Usage
///
/// ```dart
/// AppRefreshIndicator(
///   onRefresh: _onRefresh,
///   child: AppFillRemainingScrollable(
///     child: AppEmptyState(...),
///   ),
/// )
/// ```
///
/// The [child] is centered and receives unbounded height constraints, so
/// intrinsic-unfriendly widgets such as [LayoutBuilder] work correctly.
class AppFillRemainingScrollable extends StatelessWidget {
  const AppFillRemainingScrollable({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [AppSliverFillRemaining(child: child)],
    );
  }
}

/// Sliver form of [AppFillRemainingScrollable] — use this directly inside an
/// existing [CustomScrollView] (e.g. alongside a [SliverAppBar] and a
/// [SliverList]) instead of nesting a second scroll view, which slivers
/// cannot do.
///
/// Same intrinsic-sizing fix as [AppFillRemainingScrollable]: reads
/// `remainingPaintExtent` from the sliver protocol via [SliverLayoutBuilder]
/// so intrinsic-unfriendly widgets like [LayoutBuilder] still work.
class AppSliverFillRemaining extends StatelessWidget {
  const AppSliverFillRemaining({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.remainingPaintExtent,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
