import 'package:design_system/design_system.dart' show AppColors;
import 'package:design_system/src/theme/app_font.dart';
import 'package:design_system/src/theme/colors/app_colors.dart' show AppColors;
import 'package:design_system/src/theme/typography/type_scale.dart';
import 'package:flutter/material.dart';

/// **Typography system — synchronized with Design Tokens (source of truth).**
///
/// ## Architecture
///
/// ```
/// Design Tokens
///   → TypeScale (English sizes, line-heights, letter-spacing, weights)
///   → ArabicTypeScale (Arabic line-heights only)
///   → AppFont / AppFontArabic (weight presets)
///   → AppFontScaleX / AppFontArabicScaleX (size + line-height composition)
///   → AppFontStyle / AppFontArabicStyle (pre-built styles)
///   → AppTypography (ThemeExtension consumed by widgets)
/// ```
///
/// ## English typography
/// Use [AppFont] + [AppFontScaleX] or [AppFontStyle]. Line heights from
/// [TypeScale]. Title letter-spacing from [TypeScale.trackingTitle1/2/3].
/// Title 3 uses SemiBold (w600); Title 1 and 2 use Bold (w700).
///
/// ## Arabic typography
/// Use [AppFontArabic] + [AppFontArabicScaleX] or [AppFontArabicStyle].
/// Arabic line heights come from [ArabicTypeScale] — never reuse English
/// [TypeScale] line heights for Arabic locale text.
///
/// ## Token synchronization strategy
/// Design Tokens are the single source of truth. When tokens and Flutter
/// differ, Flutter is updated unless there is a documented technical limit.
///
/// ## Known token-authoring gaps (Flutter ahead — no code change)
/// - **Medium weight (w500):** Used via [TypeScale.weightMedium] but not yet in
///   `fontWeights` in tokens. Token team should add `fontWeights.inter-medium`.
/// - **Themes:** `$themes.json` is empty; [LightColors]/[DarkColors] are coded
///   directly. No token-pipeline migration planned.
///
/// [AppTypography] exposes all text roles from Figma `177:2763`. Widgets read
/// `context.appTypography.regularNormal` — they never hardcode font sizes,
/// weights, or family names.
///
/// Color for text styles must come from [AppColors], not from here.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    // ── Figma titles ─────────────────────────────────────────────────────
    required this.title1,
    required this.title2,
    required this.title3,

    // ── Figma large (18) ─────────────────────────────────────────────────
    required this.largeNone,
    required this.largeTight,
    required this.largeNormal,

    // ── Figma regular (16) ───────────────────────────────────────────────
    required this.regularNone,
    required this.regularTight,
    required this.regularNormal,

    // ── Figma small (14) ─────────────────────────────────────────────────
    required this.smallNone,
    required this.smallTight,
    required this.smallNormal,

    // ── Figma tiny (12) ──────────────────────────────────────────────────
    required this.tinyNone,
    required this.tinyTight,
    required this.tinyNormal,

    // ── Material TextTheme aliases ───────────────────────────────────────
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;

  final TextStyle largeNone;
  final TextStyle largeTight;
  final TextStyle largeNormal;

  final TextStyle regularNone;
  final TextStyle regularTight;
  final TextStyle regularNormal;

  final TextStyle smallNone;
  final TextStyle smallTight;
  final TextStyle smallNormal;

  final TextStyle tinyNone;
  final TextStyle tinyTight;
  final TextStyle tinyNormal;

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  @override
  AppTypography copyWith({
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? title3,
    TextStyle? largeNone,
    TextStyle? largeTight,
    TextStyle? largeNormal,
    TextStyle? regularNone,
    TextStyle? regularTight,
    TextStyle? regularNormal,
    TextStyle? smallNone,
    TextStyle? smallTight,
    TextStyle? smallNormal,
    TextStyle? tinyNone,
    TextStyle? tinyTight,
    TextStyle? tinyNormal,
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) {
    return AppTypography(
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      title3: title3 ?? this.title3,
      largeNone: largeNone ?? this.largeNone,
      largeTight: largeTight ?? this.largeTight,
      largeNormal: largeNormal ?? this.largeNormal,
      regularNone: regularNone ?? this.regularNone,
      regularTight: regularTight ?? this.regularTight,
      regularNormal: regularNormal ?? this.regularNormal,
      smallNone: smallNone ?? this.smallNone,
      smallTight: smallTight ?? this.smallTight,
      smallNormal: smallNormal ?? this.smallNormal,
      tinyNone: tinyNone ?? this.tinyNone,
      tinyTight: tinyTight ?? this.tinyTight,
      tinyNormal: tinyNormal ?? this.tinyNormal,
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other is! AppTypography) return this;
    TextStyle lerpStyle(TextStyle a, TextStyle b) =>
        TextStyle.lerp(a, b, t)!;

    return AppTypography(
      title1: lerpStyle(title1, other.title1),
      title2: lerpStyle(title2, other.title2),
      title3: lerpStyle(title3, other.title3),
      largeNone: lerpStyle(largeNone, other.largeNone),
      largeTight: lerpStyle(largeTight, other.largeTight),
      largeNormal: lerpStyle(largeNormal, other.largeNormal),
      regularNone: lerpStyle(regularNone, other.regularNone),
      regularTight: lerpStyle(regularTight, other.regularTight),
      regularNormal: lerpStyle(regularNormal, other.regularNormal),
      smallNone: lerpStyle(smallNone, other.smallNone),
      smallTight: lerpStyle(smallTight, other.smallTight),
      smallNormal: lerpStyle(smallNormal, other.smallNormal),
      tinyNone: lerpStyle(tinyNone, other.tinyNone),
      tinyTight: lerpStyle(tinyTight, other.tinyTight),
      tinyNormal: lerpStyle(tinyNormal, other.tinyNormal),
      displayLarge: lerpStyle(displayLarge, other.displayLarge),
      displayMedium: lerpStyle(displayMedium, other.displayMedium),
      displaySmall: lerpStyle(displaySmall, other.displaySmall),
      headlineLarge: lerpStyle(headlineLarge, other.headlineLarge),
      headlineMedium: lerpStyle(headlineMedium, other.headlineMedium),
      headlineSmall: lerpStyle(headlineSmall, other.headlineSmall),
      titleLarge: lerpStyle(titleLarge, other.titleLarge),
      titleMedium: lerpStyle(titleMedium, other.titleMedium),
      titleSmall: lerpStyle(titleSmall, other.titleSmall),
      bodyLarge: lerpStyle(bodyLarge, other.bodyLarge),
      bodyMedium: lerpStyle(bodyMedium, other.bodyMedium),
      bodySmall: lerpStyle(bodySmall, other.bodySmall),
      labelLarge: lerpStyle(labelLarge, other.labelLarge),
      labelMedium: lerpStyle(labelMedium, other.labelMedium),
      labelSmall: lerpStyle(labelSmall, other.labelSmall),
    );
  }
}

extension AppTypographyX on BuildContext {
  AppTypography get appTypography => Theme.of(this).extension<AppTypography>()!;
}

/// Applies Figma weight tiers (`177:2763`) to any base text style.
extension AppTypographyWeights on AppTypography {
  TextStyle bold(TextStyle style) =>
      style.copyWith(fontWeight: TypeScale.weightBold);

  TextStyle semiBold(TextStyle style) =>
      style.copyWith(fontWeight: TypeScale.weightSemiBold);

  TextStyle medium(TextStyle style) =>
      style.copyWith(fontWeight: TypeScale.weightMedium);

  TextStyle regular(TextStyle style) =>
      style.copyWith(fontWeight: TypeScale.weightRegular);
}

/// Builds an [AppTypography] instance from Figma `177:2763`.
AppTypography buildAppTypography() {
  final buttonLabel = AppFont.medium.regularNone;

  return AppTypography(
    title1: AppFontStyle.title1,
    title2: AppFontStyle.title2,
    title3: AppFontStyle.title3,
    largeNone: AppFontStyle.largeNone,
    largeTight: AppFontStyle.largeTight,
    largeNormal: AppFontStyle.largeNormal,
    regularNone: AppFontStyle.regularNone,
    regularTight: AppFontStyle.regularTight,
    regularNormal: AppFontStyle.regularNormal,
    smallNone: AppFontStyle.smallNone,
    smallTight: AppFontStyle.smallTight,
    smallNormal: AppFontStyle.smallNormal,
    tinyNone: AppFontStyle.tinyNone,
    tinyTight: AppFontStyle.tinyTight,
    tinyNormal: AppFontStyle.tinyNormal,
    displayLarge: AppFontStyle.title1,
    displayMedium: AppFontStyle.title2,
    displaySmall: AppFontStyle.title3,
    headlineLarge: AppFontStyle.largeNormal,
    headlineMedium: AppFontStyle.largeTight,
    headlineSmall: AppFontStyle.largeNone,
    titleLarge: AppFontStyle.regularNormal,
    titleMedium: AppFontStyle.regularTight,
    titleSmall: AppFontStyle.regularNone,
    bodyLarge: AppFontStyle.smallNormal,
    bodyMedium: AppFontStyle.smallTight,
    bodySmall: AppFontStyle.smallNone,
    labelLarge: buttonLabel,
    labelMedium: AppFontStyle.tinyNormal,
    labelSmall: AppFontStyle.tinyNone,
  );
}
