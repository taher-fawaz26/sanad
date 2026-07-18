import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Token resolver for `AppLoadingIndicator`.
///
/// Provides default sizes, durations, and color mappings from the Sanad
/// design token set. Override individual values via the widget's constructor.
abstract final class LoadingIndicatorTokens {
  LoadingIndicatorTokens._();

  // ── Geometry ───────────────────────────────────────────────────────────────

  /// Default outer diameter of the spinner (40 dp).
  static const double defaultSize = 40;

  /// Default stroke width for the arc and background ring (4 dp).
  static const double defaultStrokeWidth = 4;

  // ── Animation timing ───────────────────────────────────────────────────────

  /// Duration of one full stroke expansion/contraction cycle.
  static const Duration animationDuration = Duration(milliseconds: 1500);

  /// Duration of one full visual rotation. Slightly faster than
  /// [animationDuration] to produce a Material-quality spinning feel.
  static const Duration rotationDuration = Duration(milliseconds: 1333);

  // ── Arc sweep intervals ────────────────────────────────────────────────────

  /// The leading edge (head) of the arc accelerates in the first half of the
  /// stroke cycle.
  static const double headStartInterval = 0;
  static const double headEndInterval = 0.5;

  /// The trailing edge (tail) of the arc follows in the second half.
  static const double tailStartInterval = 0.5;
  static const double tailEndInterval = 1;

  /// Maximum arc sweep as a fraction of π — gives a 270° maximum sweep angle.
  static const double sweepPiFactor = 1.5;

  // ── Colors ─────────────────────────────────────────────────────────────────

  /// Resolves the arc color from the Sanad semantic token set.
  static Color resolveColor(AppColors colors) => colors.primary;

  /// Resolves the background ring color from the Sanad semantic token set.
  ///
  /// Falls back to `ColorScheme.surfaceContainerHighest` when [AppColors] is
  /// unavailable (e.g. in isolated tests without the full Sanad theme).
  static Color resolveBackgroundColor(
    AppColors? colors,
    ColorScheme colorScheme,
  ) {
    if (colors == null) return colorScheme.surfaceContainerHighest;
    return colors.controlFill;
  }
}
