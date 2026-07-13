import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Border Radius Tokens — sourced from Figma Sanad redesign.**
///
/// Component-level corner radii for cards, buttons, and containers.
/// Prefer [AppRadius] for component shapes; [AppDimension.radius*] for
/// small internal elements like text field outlines and badges.
abstract final class AppRadius {
  AppRadius._();

  /// 8 dp — buttons, inputs, small cards.
  static double get sm => 8.r;

  /// 10 dp — medium cards and containers.
  static double get md => 12.r;

  /// 24 dp — cards, bottom sheets, dialogs.
  static double get lg => 24.r;

  /// 32 dp — extra-large containers.
  static double get xl => 32.r;

  /// 60 dp — hero / feature sections.
  static double get xxl => 60.r;

  static BorderRadius get circularSm => BorderRadius.circular(sm);
  static BorderRadius get circularMd => BorderRadius.circular(md);
  static BorderRadius get circularLg => BorderRadius.circular(lg);
  static BorderRadius get circularXl => BorderRadius.circular(xl);
  static BorderRadius get circularXxl => BorderRadius.circular(xxl);
}
