import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Brand teal — Figma variable collection `main/*`.
abstract final class MainPalette {
  MainPalette._();

  static const Color shade50 = Color(0xFFE5FEF7);
  static const Color shade100 = Color(0xFFC3FEED);
  static const Color shade200 = Color(0xFF77FDDC);
  static const Color shade300 = Color(0xFF3BEFCA);
  static const Color shade400 = Color(0xFF35DBB8);
  static const Color shade500 = Color(0xFF30C9A9);
  static const Color shade600 = Color(0xFF26A68C);
  static const Color shade700 = Color(0xFF1A7E6B);
  static const Color shade800 = Color(0xFF126153);
  static const Color shade900 = Color(0xFF0D5044);
  static const Color shade950 = Color(0xFF052E26);

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
