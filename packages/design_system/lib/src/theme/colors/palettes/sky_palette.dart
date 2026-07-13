import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Cool blue-gray — Figma variable collection `sky/*`.
abstract final class SkyPalette {
  SkyPalette._();

  static const Color shade50 = Color(0xFFF7F9FA);
  static const Color shade100 = Color(0xFFEEF2F4);
  static const Color shade200 = Color(0xFFDCE5E9);
  static const Color shade300 = Color(0xFFC4D3DB);
  static const Color shade400 = Color(0xFF9CB5C1);
  static const Color shade500 = Color(0xFF778B95);
  static const Color shade600 = Color(0xFF5C6C75);
  static const Color shade700 = Color(0xFF48555C);
  static const Color shade800 = Color(0xFF343D43);
  static const Color shade900 = Color(0xFF262E32);
  static const Color shade950 = Color(0xFF13181A);

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
