import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Lime accent — Figma variable collection `accent/*`.
abstract final class AccentPalette {
  AccentPalette._();

  static const Color shade50 = Color(0xFFDEFFCD);
  static const Color shade100 = Color(0xFFBDFF98);
  static const Color shade200 = Color(0xFF87FC00);
  static const Color shade300 = Color(0xFF7EEB00);
  static const Color shade400 = Color(0xFF77DB00);
  static const Color shade500 = Color(0xFF72CE00);
  static const Color shade600 = Color(0xFF5FA700);
  static const Color shade700 = Color(0xFF528200);
  static const Color shade800 = Color(0xFF416400);
  static const Color shade900 = Color(0xFF355200);
  static const Color shade950 = Color(0xFF1B2F00);

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
