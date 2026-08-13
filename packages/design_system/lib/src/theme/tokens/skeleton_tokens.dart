import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/utils/constants/app_durations.dart';
import 'package:flutter/material.dart';

/// Token resolver for the app-wide skeleton loading effect.
///
/// Provides the base/highlight colors, sweep duration, and bone corner radius
/// that drive the SANAD skeleton shimmer. These are plain values (no
/// dependency on the underlying skeleton engine): the `shared_ui` gateway
/// (`AppSkeletonizer`) reads them to assemble the engine's config, so the
/// skeleton package stays behind a single import boundary.
///
/// All three colors are deliberately low-contrast neutrals derived from the
/// existing `AppColors` semantic tokens — the skeleton must read as a faded
/// preview of the real content, not a dark placeholder card:
///  * bone sweep: `disabled` (`dark-200`, `#E1E3E5` in light mode) →
///    `background` (`dark-50`, `#F9F9FA` in light mode) — both light, so the
///    sweep never flashes white; both stay dark-on-dark under `DarkColors`,
///    so this remains correct if dark mode is ever active.
///  * solid container fill (skeletonizer's own card/box backgrounds): the
///    midpoint between the two — previously hardcoded to `onBackground`
///    (`dark-900`, near-black), which is what painted every skeleton card
///    almost solid dark. That was the root cause of the too-dark skeletons.
///    Deriving it from `disabled`/`background` (rather than a fixed palette
///    shade like `sky-100`) keeps it theme-relative: light-neutral under
///    `LightColors`, dark-neutral under `DarkColors` — never a light box
///    stranded on a dark page.
abstract final class SkeletonTokens {
  SkeletonTokens._();

  /// One full shimmer sweep — reuses [AppDurations.shimmer] (1200 ms).
  static Duration get sweepDuration => AppDurations.shimmer;

  /// Corner radius applied to generated bones (8 dp — matches inputs/chips).
  static const double boneBorderRadius = 8;

  /// Resolves the dim base fill swept under the highlight — `dark-200`.
  static Color resolveBaseColor(AppColors colors) => colors.disabled;

  /// Resolves the brighter highlight that travels across the base —
  /// `dark-50`, not pure white, to keep the sweep low-contrast.
  static Color resolveHighlightColor(AppColors colors) => colors.background;

  /// Resolves the solid fill used for painted bone containers — the
  /// midpoint of the bone sweep, so containers sit visually between the two
  /// (never a dark/near-black tone, and never brighter than the highlight).
  static Color resolveContainersColor(AppColors colors) =>
      Color.lerp(colors.disabled, colors.background, 0.5)!;
}
