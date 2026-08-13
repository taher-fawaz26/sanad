import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

// The single import boundary for the skeleton engine. Feature code depends on
// these re-exports instead of `package:skeletonizer/...`, so the engine can be
// swapped without touching features.
export 'package:skeletonizer/skeletonizer.dart' show Bone, BoneMock, Skeleton;

/// Builds the SANAD skeleton config from design-system tokens.
///
/// Resolves colors from `context.appColors`, so light/dark mode is automatic;
/// the shimmer direction uses `AlignmentDirectional`, so RTL is automatic too.
/// Exposed for callers that want to seed an ambient [SkeletonizerConfig] (e.g.
/// at an app root); [AppSkeletonizer] applies it on its own and needs no such
/// wiring.
SkeletonizerConfigData sanadSkeletonizerConfig(BuildContext context) {
  final colors = context.appColors;
  return SkeletonizerConfigData(
    effect: ShimmerEffect(
      baseColor: SkeletonTokens.resolveBaseColor(colors),
      highlightColor: SkeletonTokens.resolveHighlightColor(colors),
      duration: SkeletonTokens.sweepDuration,
    ),
    textBorderRadius: TextBoneBorderRadius(
      BorderRadius.circular(SkeletonTokens.boneBorderRadius),
    ),
    containersColor: SkeletonTokens.resolveContainersColor(colors),
    enableSwitchAnimation: true,
  );
}

/// App-wide gateway for DATA/READ skeleton loading.
///
/// Wrap the *real* content tree; when [enabled] is true the layout renders as
/// animated bones instead of a bespoke skeleton widget. Bind [enabled] to the
/// *initial* load flag only (e.g. `PaginationData.isLoadingFirstPage`) — never
/// a blanket `isLoading` — so refresh/pagination keep existing content on
/// screen instead of wiping it.
///
/// ```dart
/// AppSkeletonizer(
///   enabled: state.isLoadingFirstPage,
///   child: WorkerList(items: state.items),
/// )
/// ```
///
/// Use [AppSkeletonizer.sliver] inside a `CustomScrollView` (details pages,
/// sliver lists). No feature should import `package:skeletonizer` directly —
/// `Bone`, `BoneMock`, and `Skeleton` are re-exported from this library.
class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({
    required this.enabled,
    required this.child,
    super.key,
  }) : _sliver = false;

  /// Sliver variant for `CustomScrollView` bodies.
  const AppSkeletonizer.sliver({
    required this.enabled,
    required this.child,
    super.key,
  }) : _sliver = true;

  /// Whether to paint [child] as skeleton bones. Prefer binding to the
  /// initial-load flag so already-loaded content is never replaced.
  final bool enabled;

  /// The real content tree (box child, or sliver child for `.sliver`).
  final Widget child;

  final bool _sliver;

  @override
  Widget build(BuildContext context) {
    final skeletonizer = _sliver
        ? Skeletonizer.sliver(enabled: enabled, child: child)
        : Skeletonizer(enabled: enabled, child: child);

    // Provide the SANAD config to the Skeletonizer (and any descendant bones)
    // via the ambient config it already reads from. Keeps a single visual
    // language without requiring app-root wiring.
    return SkeletonizerConfig(
      data: sanadSkeletonizerConfig(context),
      child: skeletonizer,
    );
  }
}
