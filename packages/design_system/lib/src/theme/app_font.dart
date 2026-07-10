import 'package:design_system/design_system.dart' show AppTypography;
import 'package:design_system/src/theme/typography/app_typography.dart' show AppTypography;
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:design_system/src/theme/typography/type_scale.dart';
import 'package:flutter/material.dart';

// ─── Font family name constants ──────────────────────────────────────────────
// Matches the `family:` key in pubspec.yaml exactly.
// Use these constants instead of raw strings so a rename is a one-line change.

/// Registered font family names — match pubspec.yaml `family:` values exactly.
abstract final class AppFontFamily {
  AppFontFamily._();

  /// Primary UI font. Used for body, title, and label styles. (Figma: Poppins)
  static const String poppins = 'Poppins';

  /// Arabic-locale font. Used when the app language is Arabic.
  /// (Figma: Noto Sans Arabic)
  static const String notoSansArabic = 'NotoSansArabic';
}

// ─── Poppins weight presets ──────────────────────────────────────────────────

/// **Base font style presets by weight — Poppins (primary UI font).**
///
/// Combine with [AppFontScaleX] for Figma `177:2763` size + line-height pairs:
///
/// ```dart
/// AppFont.medium.regularNormal   // Poppins w500, 16/24
/// AppFont.bold.title1            // Poppins w700, 48/56
/// ```
abstract final class AppFont {
  AppFont._();

  static const TextStyle regular = TextStyle(
    fontFamily: AppFontFamily.poppins,
    fontWeight: TypeScale.weightRegular,
    letterSpacing: 0,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: AppFontFamily.poppins,
    fontWeight: TypeScale.weightMedium,
    letterSpacing: 0,
  );

  static const TextStyle bold = TextStyle(
    fontFamily: AppFontFamily.poppins,
    fontWeight: TypeScale.weightBold,
    letterSpacing: 0,
  );

  /// Backward-compatible alias for [regular].
  static const TextStyle normal = regular;
}

// ─── Noto Sans Arabic weight presets ─────────────────────────────────────────

/// **Noto Sans Arabic presets — Arabic locale font.**
///
/// Use when `context.locale.languageCode == 'ar'` or via [TextStyle]
/// `fontFamilyFallback` so Arabic text falls through automatically.
///
/// ```dart
/// AppFontArabic.regular.regularNormal
/// ```
abstract final class AppFontArabic {
  AppFontArabic._();

  static const TextStyle regular = TextStyle(
    fontFamily: AppFontFamily.notoSansArabic,
    fontWeight: TypeScale.weightRegular,
    letterSpacing: 0,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: AppFontFamily.notoSansArabic,
    fontWeight: TypeScale.weightMedium,
    letterSpacing: 0,
  );

  static const TextStyle bold = TextStyle(
    fontFamily: AppFontFamily.notoSansArabic,
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
      );

  TextStyle get title2 => copyWith(
        fontSize: TypeScale.title2,
        height: TypeScale.lineHeightTitle2,
      );

  TextStyle get title3 => copyWith(
        fontSize: TypeScale.title3,
        height: TypeScale.lineHeightTitle3,
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
  static final TextStyle title3 = AppFont.bold.title3;

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
