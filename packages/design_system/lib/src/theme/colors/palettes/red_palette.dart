import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Error / destructive — Figma variable collection `red/*`.
abstract final class RedPalette {
  RedPalette._();

  static const Color shade50 = Color(0xFFFFF2F2);
  static const Color shade100 = Color(0xFFFFE5E5);
  static const Color shade200 = Color(0xFFFFD1D1);
  static const Color shade300 = Color(0xFFFFB2B4);
  static const Color shade400 = Color(0xFFFF8B91);
  static const Color shade500 = Color(0xFFFF5666);
  static const Color shade600 = Color(0xFFEE003E);
  static const Color shade700 = Color(0xFFC3002E);
  static const Color shade800 = Color(0xFFA00023);
  static const Color shade900 = Color(0xFF87001B);
  static const Color shade950 = Color(0xFF52000E);

  static const ColorScale scale = ColorScale(
    shade50: shade50,
    shade100: shade100,
    shade200: shade200,
    shade300: shade300,
    shade400: shade400,
    shade500: shade500,
    shade600: shade600,
    shade700: shade700,
    shade800: shade800,
    shade900: shade900,
    shade950: shade950,
  );
}
