import 'package:design_system/design_system.dart' show AppTypography;
import 'package:design_system/src/theme/typography/app_typography.dart' show AppTypography;
import 'package:design_system/src/theme/typography/arabic_type_scale.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:design_system/src/theme/typography/type_scale.dart';
import 'package:flutter/material.dart';

// ─── Font family name constants ──────────────────────────────────────────────
// Matches the `family:` key in pubspec.yaml exactly.
// Use these constants instead of raw strings so a rename is a one-line change.

/// Registered font family names — match pubspec.yaml `family:` values exactly.
abstract final class AppFontFamily {
  AppFontFamily._();

  /// Primary UI font — Inter. Used for body, title, and label styles.
  static const String inter = 'Inter';

  /// Arabic-locale font — IBM Plex Sans Arabic.
  /// Used when the app language is Arabic.
  static const String ibmPlexSansArabic = 'IBMPlexSansArabic';
}

// ─── Inter weight presets ────────────────────────────────────────────────────

/// **Base font style presets by weight — Inter (primary UI font).**
///
/// Combine with [AppFontScaleX] for Figma `177:2763` size + line-height pairs:
///
/// ```dart
/// AppFont.medium.regularNormal   // Inter w500, 16/24
/// AppFont.semiBold.title3        // Inter w600, 24/32
/// AppFont.bold.title1            // Inter w700, 48/56
/// ```
abstract final class AppFont {
  AppFont._();

  static const TextStyle regular = TextStyle(
    fontFamily: AppFontFamily.inter,
    fontWeight: TypeScale.weightRegular,
    letterSpacing: 0,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: AppFontFamily.inter,
    fontWeight: TypeScale.weightMedium,
    letterSpacing: 0,
  );

  static const TextStyle semiBold = TextStyle(
    fontFamily: AppFontFamily.inter,
    fontWeight: TypeScale.weightSemiBold,
    letterSpacing: 0,
  );

  static const TextStyle bold = TextStyle(
    fontFamily: AppFontFamily.inter,
    fontWeight: TypeScale.weightBold,
    letterSpacing: 0,
  );

  /// Backward-compatible alias for [regular].
  static const TextStyle normal = regular;
}

// ─── IBM Plex Sans Arabic weight presets ─────────────────────────────────────

/// **IBM Plex Sans Arabic presets — Arabic locale font.**
///
/// Use when `context.locale.languageCode == 'ar'` or via [TextStyle]
/// `fontFamilyFallback` so Arabic text falls through automatically.
///
/// ```dart
/// AppFontArabic.regular.arRegularNormal
/// AppFontArabic.semiBold.arTitle3
/// ```
abstract final class AppFontArabic {
  AppFontArabic._();

  static const TextStyle regular = TextStyle(
    fontFamily: AppFontFamily.ibmPlexSansArabic,
    fontWeight: TypeScale.weightRegular,
    letterSpacing: 0,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: AppFontFamily.ibmPlexSansArabic,
    fontWeight: TypeScale.weightMedium,
    letterSpacing: 0,
  );

  static const TextStyle semiBold = TextStyle(
    fontFamily: AppFontFamily.ibmPlexSansArabic,
    fontWeight: TypeScale.weightSemiBold,
    letterSpacing: 0,
  );

  static const TextStyle bold = TextStyle(
    fontFamily: AppFontFamily.ibmPlexSansArabic,
    fontWeight: TypeScale.weightBold,
    letterSpacing: 0,
  );
}

// ─── Figma type scale (`177:2763`) ──────────────────────────────────────────

/// **Figma `177:2763` size + line-height tokens on any [TextStyle].**
///
/// Apply after an [AppFont] or [AppFontArabic] weight preset:
///
/// ```dart
/// AppFont.regular.smallTight
/// AppFont.bold.title2
/// ```
extension AppFontScaleX on TextStyle {
  // ── Titles ────────────────────────────────────────────────────────────────
  TextStyle get title1 => copyWith(
        fontSize: TypeScale.title1,
        height: TypeScale.lineHeightTitle1,
        letterSpacing: TypeScale.trackingTitle1,
      );

  TextStyle get title2 => copyWith(
        fontSize: TypeScale.title2,
        height: TypeScale.lineHeightTitle2,
        letterSpacing: TypeScale.trackingTitle2,
      );

  TextStyle get title3 => copyWith(
        fontSize: TypeScale.title3,
        height: TypeScale.lineHeightTitle3,
        letterSpacing: TypeScale.trackingTitle3,
      );

  // ── Large (18) ────────────────────────────────────────────────────────────
  TextStyle get largeNone => copyWith(
        fontSize: TypeScale.large,
        height: TypeScale.lineHeightLargeNone,
      );

  TextStyle get largeTight => copyWith(
        fontSize: TypeScale.large,
        height: TypeScale.lineHeightLargeTight,
      );

  TextStyle get largeNormal => copyWith(
        fontSize: TypeScale.large,
        height: TypeScale.lineHeightLargeNormal,
      );

  // ── Regular (16) ──────────────────────────────────────────────────────────
  TextStyle get regularNone => copyWith(
        fontSize: TypeScale.regular,
        height: TypeScale.lineHeightRegularNone,
      );

  TextStyle get regularTight => copyWith(
        fontSize: TypeScale.regular,
        height: TypeScale.lineHeightRegularTight,
      );

  TextStyle get regularNormal => copyWith(
        fontSize: TypeScale.regular,
        height: TypeScale.lineHeightRegularNormal,
      );

  // ── Small (14) ────────────────────────────────────────────────────────────
  TextStyle get smallNone => copyWith(
        fontSize: TypeScale.small,
        height: TypeScale.lineHeightSmallNone,
      );

  TextStyle get smallTight => copyWith(
        fontSize: TypeScale.small,
        height: TypeScale.lineHeightSmallTight,
      );

  TextStyle get smallNormal => copyWith(
        fontSize: TypeScale.small,
        height: TypeScale.lineHeightSmallNormal,
      );

  // ── Tiny (12) ─────────────────────────────────────────────────────────────
  TextStyle get tinyNone => copyWith(
        fontSize: TypeScale.tiny,
        height: TypeScale.lineHeightTinyNone,
      );

  TextStyle get tinyTight => copyWith(
        fontSize: TypeScale.tiny,
        height: TypeScale.lineHeightTinyTight,
      );

  TextStyle get tinyNormal => copyWith(
        fontSize: TypeScale.tiny,
        height: TypeScale.lineHeightTinyNormal,
      );
}

/// **Pre-composed Figma `177:2763` text styles — Regular weight defaults.**
///
/// Prefer [AppTypography] in widgets; use these for one-off composition or
/// tests outside a [BuildContext].
abstract final class AppFontStyle {
  AppFontStyle._();

  static final TextStyle title1 = AppFont.bold.title1;
  static final TextStyle title2 = AppFont.bold.title2;
  static final TextStyle title3 = AppFont.semiBold.title3;

  static final TextStyle largeNone = AppFont.regular.largeNone;
  static final TextStyle largeTight = AppFont.regular.largeTight;
  static final TextStyle largeNormal = AppFont.regular.largeNormal;

  static final TextStyle regularNone = AppFont.regular.regularNone;
  static final TextStyle regularTight = AppFont.regular.regularTight;
  static final TextStyle regularNormal = AppFont.regular.regularNormal;

  static final TextStyle smallNone = AppFont.regular.smallNone;
  static final TextStyle smallTight = AppFont.regular.smallTight;
  static final TextStyle smallNormal = AppFont.regular.smallNormal;

  static final TextStyle tinyNone = AppFont.regular.tinyNone;
  static final TextStyle tinyTight = AppFont.regular.tinyTight;
  static final TextStyle tinyNormal = AppFont.regular.tinyNormal;
}

/// **Arabic type scale (`arabic.*` tokens) on any [TextStyle].**
///
/// Apply after an [AppFontArabic] weight preset. Uses [ArabicTypeScale] line
/// heights — do not use [AppFontScaleX] for Arabic locale text.
///
/// ```dart
/// AppFontArabic.regular.arRegularNormal
/// AppFontArabic.semiBold.arTitle3
/// ```
extension AppFontArabicScaleX on TextStyle {
  // ── Titles ────────────────────────────────────────────────────────────────
  TextStyle get arTitle1 => copyWith(
        fontSize: TypeScale.title1,
        height: ArabicTypeScale.lineHeightTitle1,
        letterSpacing: TypeScale.trackingTitle1,
      );

  TextStyle get arTitle2 => copyWith(
        fontSize: TypeScale.title2,
        height: ArabicTypeScale.lineHeightTitle2,
        letterSpacing: TypeScale.trackingTitle2,
      );

  TextStyle get arTitle3 => copyWith(
        fontSize: TypeScale.title3,
        height: ArabicTypeScale.lineHeightTitle3,
        letterSpacing: TypeScale.trackingTitle3,
      );

  // ── Large (18) ────────────────────────────────────────────────────────────
  TextStyle get arLargeNone => copyWith(
        fontSize: TypeScale.large,
        height: ArabicTypeScale.lineHeightLargeNone,
      );

  TextStyle get arLargeTight => copyWith(
        fontSize: TypeScale.large,
        height: ArabicTypeScale.lineHeightLargeTight,
      );

  TextStyle get arLargeNormal => copyWith(
        fontSize: TypeScale.large,
        height: ArabicTypeScale.lineHeightLargeNormal,
      );

  // ── Regular (16) ──────────────────────────────────────────────────────────
  TextStyle get arRegularNone => copyWith(
        fontSize: TypeScale.regular,
        height: ArabicTypeScale.lineHeightRegularNone,
      );

  TextStyle get arRegularTight => copyWith(
        fontSize: TypeScale.regular,
        height: ArabicTypeScale.lineHeightRegularTight,
      );

  TextStyle get arRegularNormal => copyWith(
        fontSize: TypeScale.regular,
        height: ArabicTypeScale.lineHeightRegularNormal,
      );

  // ── Small (14) ────────────────────────────────────────────────────────────
  TextStyle get arSmallNone => copyWith(
        fontSize: TypeScale.small,
        height: ArabicTypeScale.lineHeightSmallNone,
      );

  TextStyle get arSmallTight => copyWith(
        fontSize: TypeScale.small,
        height: ArabicTypeScale.lineHeightSmallTight,
      );

  TextStyle get arSmallNormal => copyWith(
        fontSize: TypeScale.small,
        height: ArabicTypeScale.lineHeightSmallNormal,
      );

  // ── Tiny (12) ─────────────────────────────────────────────────────────────
  TextStyle get arTinyNone => copyWith(
        fontSize: TypeScale.tiny,
        height: ArabicTypeScale.lineHeightTinyNone,
      );

  TextStyle get arTinyTight => copyWith(
        fontSize: TypeScale.tiny,
        height: ArabicTypeScale.lineHeightTinyTight,
      );

  TextStyle get arTinyNormal => copyWith(
        fontSize: TypeScale.tiny,
        height: ArabicTypeScale.lineHeightTinyNormal,
      );
}

/// **Pre-composed Arabic text styles — Regular weight defaults.**
///
/// Prefer [AppFontArabicStyle] when locale is Arabic; [AppFontStyle] for
/// English. Use [AppTypography] in widgets when possible.
abstract final class AppFontArabicStyle {
  AppFontArabicStyle._();

  static final TextStyle title1 = AppFontArabic.bold.arTitle1;
  static final TextStyle title2 = AppFontArabic.bold.arTitle2;
  static final TextStyle title3 = AppFontArabic.semiBold.arTitle3;

  static final TextStyle largeNone = AppFontArabic.regular.arLargeNone;
  static final TextStyle largeTight = AppFontArabic.regular.arLargeTight;
  static final TextStyle largeNormal = AppFontArabic.regular.arLargeNormal;

  static final TextStyle regularNone = AppFontArabic.regular.arRegularNone;
  static final TextStyle regularTight = AppFontArabic.regular.arRegularTight;
  static final TextStyle regularNormal = AppFontArabic.regular.arRegularNormal;

  static final TextStyle smallNone = AppFontArabic.regular.arSmallNone;
  static final TextStyle smallTight = AppFontArabic.regular.arSmallTight;
  static final TextStyle smallNormal = AppFontArabic.regular.arSmallNormal;

  static final TextStyle tinyNone = AppFontArabic.regular.arTinyNone;
  static final TextStyle tinyTight = AppFontArabic.regular.arTinyTight;
  static final TextStyle tinyNormal = AppFontArabic.regular.arTinyNormal;
}

/// Legacy size aliases — map old generic tokens to the Figma scale.
///
/// Prefer [AppFontScaleX] for new code.
extension AppFontSizeX on TextStyle {
  /// 12 dp — maps to Figma **Tiny**.
  TextStyle get sm => copyWith(fontSize: TypeScale.tiny);

  /// 14 dp — maps to Figma **Small**.
  TextStyle get md => copyWith(fontSize: TypeScale.small);

  /// 16 dp — maps to Figma **Regular**.
  TextStyle get lg => copyWith(fontSize: TypeScale.regular);

  /// 24 dp — maps to Figma **Title 3**.
  TextStyle get xxl => copyWith(fontSize: TypeScale.title3);

  /// 10 dp — legacy micro size (not in Figma `177:2763`).
  TextStyle get xs => copyWith(fontSize: 10.rfs);

  /// 20 dp — legacy size (not in Figma `177:2763`).
  TextStyle get xl => copyWith(fontSize: 20.rfs);
}
