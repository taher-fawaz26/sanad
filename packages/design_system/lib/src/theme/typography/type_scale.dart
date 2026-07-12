import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// **Typography scale tokens — Figma `177:2763` (Inter / IBM Plex Sans Arabic).**
///
/// Each size tier exposes three line-height variants:
/// - **None** — line height equals font size (1.0)
/// - **Tight** — compact multi-line rhythm
/// - **Normal** — comfortable reading rhythm
///
/// Each variant supports four weights in UI: **Regular** (400),
/// **Medium** (500), **SemiBold** (600), **Bold** (700).
/// Title 1 and Title 2 use Bold; Title 3 uses SemiBold per design tokens.
///
/// **Token authoring gap:** [weightMedium] (w500) is used in Flutter but not
/// yet defined in `fontWeights` in the design tokens. Implementation is
/// intentionally kept until tokens add `fontWeights.inter-medium`.
abstract final class TypeScale {
  TypeScale._();

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // ── Titles ────────────────────────────────────────────────────────────────
  static double get title1 => 48.rfs;
  static double get title2 => 32.rfs;
  static double get title3 => 24.rfs;

  static const double lineHeightTitle1 = 56 / 48;
  static const double lineHeightTitle2 = 36 / 32;
  static const double lineHeightTitle3 = 32 / 24;

  /// Title letter-spacing from design tokens (percentage × font size).
  static const double trackingTitle1 = -0.96; // 48 × -2%
  static const double trackingTitle2 = -0.32; // 32 × -1%
  static const double trackingTitle3 = -0.12; // 24 × -0.5%

  // ── Large (18) ─────────────────────────────────────────────────────────
  static double get large => 18.rfs;

  static const double lineHeightLargeNone = 1;
  static const double lineHeightLargeTight = 20 / 18;
  static const double lineHeightLargeNormal = 24 / 18;

  // ── Regular (16) ──────────────────────────────────────────────────────────
  static double get regular => 16.rfs;

  static const double lineHeightRegularNone = 1;
  static const double lineHeightRegularTight = 20 / 16;
  static const double lineHeightRegularNormal = 24 / 16;

  // ── Small (14) ────────────────────────────────────────────────────────────
  static double get small => 14.rfs;

  static const double lineHeightSmallNone = 1;
  static const double lineHeightSmallTight = 16 / 14;
  static const double lineHeightSmallNormal = 20 / 14;

  // ── Tiny (12) ─────────────────────────────────────────────────────────────
  static double get tiny => 12.rfs;

  static const double lineHeightTinyNone = 1;
  static const double lineHeightTinyTight = 14 / 12;
  static const double lineHeightTinyNormal = 16 / 12;

  // ── Material TextTheme aliases (backward-compatible) ───────────────────
  static double get displayLg => title1;
  static double get displayMd => title2;
  static double get displaySm => title3;

  static double get headlineLg => large;
  static double get headlineMd => large;
  static double get headlineSm => large;

  static double get titleLg => regular;
  static double get titleMd => regular;
  static double get titleSm => regular;

  static double get bodyLg => small;
  static double get bodyMd => small;
  static double get bodySm => tiny;

  static double get labelLg => regular;
  static double get labelMd => tiny;
  static double get labelSm => tiny;

  static const double lineHeightDisplay = lineHeightTitle1;
  static const double lineHeightHeadline = lineHeightLargeNormal;
  static const double lineHeightTitle = lineHeightRegularNormal;
  static const double lineHeightBodyLg = lineHeightSmallNormal;
  static const double lineHeightBodyMd = lineHeightSmallTight;
  static const double lineHeightBodySm = lineHeightTinyNone;
  static const double lineHeightLabel = lineHeightTinyNone;
  static const double lineHeightPrimaryButton = lineHeightRegularNone;
  static const double lineHeightSecondaryButton = lineHeightRegularNone;

  static const double trackingDisplay = 0;
  static const double trackingHeadline = 0;
  static const double trackingTitleLg = 0;
  static const double trackingTitleMd = 0;
  static const double trackingTitleSm = 0;
  static const double trackingBodyLg = 0;
}
