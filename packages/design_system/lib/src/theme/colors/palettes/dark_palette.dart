import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Neutral gray — Figma variable collection `dark/*`.
abstract final class DarkPalette {
  DarkPalette._();

  static const Color shade50 = Color(0xFFF9F9FA);
  static const Color shade100 = Color(0xFFF2F3F3);
  static const Color shade200 = Color(0xFFE1E3E5);
  static const Color shade300 = Color(0xFFCCD0D2);
  static const Color shade400 = Color(0xFF8F9599);
  static const Color shade500 = Color(0xFF72777A);
  static const Color shade600 = Color(0xFF575B5E);
  static const Color shade700 = Color(0xFF45484A);
  static const Color shade800 = Color(0xFF2F3233);
  static const Color shade900 = Color(0xFF212324);
  static const Color shade950 = Color(0xFF0F1011);

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
