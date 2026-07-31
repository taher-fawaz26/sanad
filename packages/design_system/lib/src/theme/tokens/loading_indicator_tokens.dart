import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
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

  /// Default stroke width for the arc (5 dp).
  static const double defaultStrokeWidth = 5;

  // ── Animation timing ───────────────────────────────────────────────────────

  /// Duration of one full 360° rotation.
  static const Duration rotationDuration = Duration(milliseconds: 1100);

  // ── Sweep geometry ─────────────────────────────────────────────────────────

  /// Visible sweep as a fraction of the full circle — 0.75 = 270°.
  static const double sweepFraction = 0.75;

  // ── Gradient stops ─────────────────────────────────────────────────────────

  /// Stop positions for the four-colour sweep gradient.
  ///
  /// Layout (tail → head):
  /// ```plaintext
  /// 0.00  transparent  ← tail (invisible, round cap here is hidden)
  /// 0.42  transparent  ← still transparent
  /// 0.78  lightColor   ← gradient ramps up
  /// 1.00  arcColor     ← solid leading tip (round cap visible here)
  /// ```
  static const List<double> gradientStops = [0.0, 0.42, 0.78, 1.0];

  // ── Colors ─────────────────────────────────────────────────────────────────

  /// Resolves the solid leading-tip color (primary brand teal).
  static Color resolveColor(AppColors colors) => colors.primary;

  /// Resolves the lighter teal used mid-gradient (brand shade 300).
  ///
  /// Distinct from [resolveColor] so the gradient has a visible teal ramp
  /// rather than a simple opacity fade. When the caller provides a custom
  /// `color`, the light variant is derived as 50% opacity of that color.
  static Color resolveLightColor(AppColors colors) => MainPalette.shade300;
}
