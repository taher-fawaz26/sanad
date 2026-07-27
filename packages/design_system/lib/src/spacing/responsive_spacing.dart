import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Single-pass clamp-based responsive spacing engine.**
///
/// Mirrors the font engine pattern — one multiplication step, then a manual
/// branch clamp. No BuildContext, no MediaQuery, O(1).
///
/// Clamp bounds: [base × 0.85, base × 1.25]
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

/// **Spacing scale — Figma `892:4898` Guide (16px base).**
///
/// All values are design-spec dp sizes routed through [responsiveSpacing].
/// Widgets must never use raw EdgeInsets literals or `.w` / `.h` extensions.
///
/// Figma steps (Name → rem → px) map to semantic tokens:
///
/// | Step | rem     | dp  | Token |
/// |------|---------|-----|-------|
/// | 1    | 0.25rem | 4   | [xs] |
/// | 2    | 0.5rem  | 8   | [sm] |
/// | 3    | 0.75rem | 12  | [md] |
/// | 4    | 1rem    | 16  | [lg] |
/// | 5    | 1.25rem | 20  | [xl] |
/// | 6    | 1.5rem  | 24  | [xxl] |
/// | 8    | 2rem    | 32  | [xxxl] |
/// | 10   | 2.5rem  | 40  | [xxxxl] |
/// | 12   | 3rem    | 48  | [xxxxxl] |
/// | 16   | 4rem    | 64  | [space64] |
/// | 20   | 5rem    | 80  | [pageGap] / [space80] |
/// | 24   | 6rem    | 96  | [space96] |
/// | 32   | 8rem    | 128 | [space128] |
/// | 40   | 10rem   | 160 | [space160] |
/// | 48   | 12rem   | 192 | [space192] |
/// | 56   | 14rem   | 224 | [space224] |
/// | 64   | 16rem   | 256 | [space256] |
abstract final class AppSpacing {
  AppSpacing._();

  /// 4 dp — Figma step 1 (0.25rem). Micro gaps, icon-to-label nudges.
  static double get xs => responsiveSpacing(4);

  /// 8 dp — Figma step 2 (0.5rem). Compact internal padding.
  static double get sm => responsiveSpacing(8);

  /// 12 dp — Figma step 3 (0.75rem). Default list/card inset.
  static double get md => responsiveSpacing(12);

  /// 13 dp — tight card inset when design calls for 12 + 1 dp.
  /// Not in Figma spacing guide — legacy app-specific token.
  static double get mdPlus => responsiveSpacing(13);

  /// 17 dp — inline notice card padding (e.g. emergency priority callout).
  /// Not in Figma spacing guide — legacy app-specific token.
  static double get emergencyNoticePaddingAll => responsiveSpacing(17);

  /// 18 dp — emergency service grid tile padding.
  /// Not in Figma spacing guide — legacy app-specific token.
  static double get emergencyServiceTilePaddingAll => responsiveSpacing(18);

  /// 16 dp — Figma step 4 (1rem). Default screen horizontal padding.
  static double get lg => responsiveSpacing(16);

  /// 20 dp — Figma step 5 (1.25rem). Comfortable vertical rhythm.
  static double get xl => responsiveSpacing(20);

  /// 24 dp — Figma step 6 (1.5rem). Dialog padding, hero section spacing.
  static double get xxl => responsiveSpacing(24);

  /// 32 dp — Figma step 8 (2rem). Large section divider.
  static double get xxxl => responsiveSpacing(32);

  /// 40 dp — Figma step 10 (2.5rem). Extra-large hero gap.
  static double get xxxxl => responsiveSpacing(40);

  /// 48 dp — Figma step 12 (3rem).
  static double get xxxxxl => responsiveSpacing(48);

  /// 64 dp — Figma step 16 (4rem).
  static double get space64 => responsiveSpacing(64);

  /// 60 dp — section divider gaps (legacy layout token, not in Figma guide).
  static double get section => responsiveSpacing(60);

  /// 80 dp — Figma step 20 (5rem). Page section gaps.
  static double get pageGap => responsiveSpacing(80);

  /// Alias for [pageGap] — Figma step 20.
  static double get space80 => pageGap;

  /// 96 dp — Figma step 24 (6rem).
  static double get space96 => responsiveSpacing(96);

  /// 110 dp — large page section gaps (legacy layout token).
  static double get largeSection => responsiveSpacing(110);

  /// 128 dp — Figma step 32 (8rem).
  static double get space128 => responsiveSpacing(128);

  /// 140 dp — page horizontal padding (legacy Figma layout token).
  static double get pagePadding => responsiveSpacing(140);

  /// 160 dp — Figma step 40 (10rem).
  static double get space160 => responsiveSpacing(160);

  /// 192 dp — Figma step 48 (12rem).
  static double get space192 => responsiveSpacing(192);

  /// 224 dp — Figma step 56 (14rem).
  static double get space224 => responsiveSpacing(224);

  /// 256 dp — Figma step 64 (16rem).
  static double get space256 => responsiveSpacing(256);
}

// ─── AppSpacingDp ─────────────────────────────────────────────────────────────

/// **Const design-spec dp values for use in `const` constructors.**
///
/// Use these whenever you need a `const` widget (e.g. `const SizedBox`,
/// `const EdgeInsets`) and the spacing value should reflect the Figma
/// design-spec dp rather than a screen-scaled value.
///
/// For screen-size-aware spacing at runtime, use [AppSpacing] instead.
///
/// ```dart
/// // const-safe:
/// const SizedBox(height: AppSpacingDp.xxl)
/// const EdgeInsets.symmetric(horizontal: AppSpacingDp.xxl)
///
/// // screen-scaled (non-const):
/// SizedBox(height: AppSpacing.xxl)
/// ```
abstract final class AppSpacingDp {
  AppSpacingDp._();

  /// 4 dp — Figma step 1.
  static const double xs = 4;

  /// 8 dp — Figma step 2.
  static const double sm = 8;

  /// 12 dp — Figma step 3.
  static const double md = 12;

  /// 16 dp — Figma step 4.
  static const double lg = 16;

  /// 20 dp — Figma step 5.
  static const double xl = 20;

  /// 24 dp — Figma step 6.
  static const double xxl = 24;

  /// 32 dp — Figma step 8.
  static const double xxxl = 32;

  /// 40 dp — Figma step 10.
  static const double xxxxl = 40;

  /// 48 dp — Figma step 12.
  static const double xxxxxl = 48;

  /// 64 dp — Figma step 16.
  static const double space64 = 64;

  /// 80 dp — Figma step 20.
  static const double pageGap = 80;

  /// 96 dp — Figma step 24.
  static const double space96 = 96;

  /// 128 dp — Figma step 32.
  static const double space128 = 128;

  /// 160 dp — Figma step 40.
  static const double space160 = 160;

  /// 192 dp — Figma step 48.
  static const double space192 = 192;

  /// 224 dp — Figma step 56.
  static const double space224 = 224;

  /// 256 dp — Figma step 64.
  static const double space256 = 256;
}
