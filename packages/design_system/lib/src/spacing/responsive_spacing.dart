import 'package:flutter/cupertino.dart' show BuildContext, EdgeInsets, MediaQuery;
import 'package:flutter/material.dart' show BuildContext, EdgeInsets, MediaQuery;
import 'package:flutter/widgets.dart' show BuildContext, EdgeInsets, MediaQuery;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Single-pass clamp-based responsive spacing engine.**
///
/// Mirrors the font engine pattern — one multiplication step, then a manual
/// branch clamp. No [BuildContext], no [MediaQuery], O(1).
///
/// Clamp bounds: [base × 0.85, base × 1.20]
///
/// Usage (via token class — never call directly in widgets):
/// ```dart
/// padding: EdgeInsets.all(AppSpacing.md)   // 12 dp design spec
/// ```
double responsiveSpacing(double base) {
  final scaled = base * ScreenUtil().scaleWidth;

  // Manual branch avoids num.clamp() boxing on the hot path.
  final min = base * 0.85;
  final max = base * 1.25;
  if (scaled < min) return min;
  if (scaled > max) return max;
  return scaled;
}

// ─── AppSpacing ──────────────────────────────────────────────────────────────

/// **4-based spacing token scale.**
///
/// All values are design-spec dp sizes routed through [responsiveSpacing].
/// Widgets must never use raw [EdgeInsets] literals or `.w` / `.h` extensions.
///
/// | Token   | Base (dp) |
/// |---------|-----------|
/// | `xs`    | 4         |
/// | `sm`    | 8         |
/// | `md`    | 12        |
/// | `lg`    | 16        |
/// | `xl`    | 20        |
/// | `xxl`   | 24        |
/// | `xxxl`  | 32        |
/// | `xxxxl` | 40        |
abstract final class AppSpacing {
  AppSpacing._();

  /// 4 dp — micro gaps, icon-to-label nudges.
  static double get xs => responsiveSpacing(4);

  /// 8 dp — compact internal padding, small separator.
  static double get sm => responsiveSpacing(8);

  /// 12 dp — default list/grid item padding, standard card inset.
  static double get md => responsiveSpacing(12);

  /// 13 dp — tight card inset when design calls for 12 + 1 dp.
  static double get mdPlus => responsiveSpacing(13);

  /// 17 dp — inline notice card padding (e.g. emergency priority callout).
  static double get emergencyNoticePaddingAll => responsiveSpacing(17);

  /// 18 dp — emergency service grid tile padding (lg + half xs).
  static double get emergencyServiceTilePaddingAll => responsiveSpacing(18);

  /// 16 dp — default screen horizontal padding, section gap.
  static double get lg => responsiveSpacing(16);

  /// 20 dp — comfortable vertical rhythm.
  static double get xl => responsiveSpacing(20);

  /// 24 dp — dialog padding, hero section spacing.
  static double get xxl => responsiveSpacing(24);

  /// 32 dp — large section divider, empty-state padding.
  static double get xxxl => responsiveSpacing(32);

  /// 40 dp — extra-large hero gap.
  static double get xxxxl => responsiveSpacing(40);

  /// 48 dp — maximum spacing for most layouts, used sparingly.
  static double get xxxxxl => responsiveSpacing(48);

  /// 60 dp — section divider gaps (Figma section spacing).
  static double get section => responsiveSpacing(60);

  /// 80 dp — page section gaps.
  static double get pageGap => responsiveSpacing(80);

  /// 110 dp — large page section gaps.
  static double get largeSection => responsiveSpacing(110);

  /// 140 dp — page horizontal padding (Figma layout).
  static double get pagePadding => responsiveSpacing(140);
}
