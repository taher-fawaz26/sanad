import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:flutter/material.dart';

/// Warning / highlight amber — Figma variable collection `yallow/*`.
abstract final class YellowPalette {
  YellowPalette._();

  static const Color shade50 = Color(0xFFFFF7ED);
  static const Color shade100 = Color(0xFFFFEED7);
  static const Color shade200 = Color(0xFFFFDFB2);
  static const Color shade300 = Color(0xFFFFCB7B);
  static const Color shade400 = Color(0xFFFFB323);
  static const Color shade500 = Color(0xFFECA100);
  static const Color shade600 = Color(0xFFCA8300);
  static const Color shade700 = Color(0xFFA16000);
  static const Color shade800 = Color(0xFF814700);
  static const Color shade900 = Color(0xFF6B3900);
  static const Color shade950 = Color(0xFF3E2000);

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
