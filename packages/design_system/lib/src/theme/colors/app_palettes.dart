import 'package:design_system/src/theme/colors/color_scale.dart';
import 'package:design_system/src/theme/colors/palettes/accent_palette.dart';
import 'package:design_system/src/theme/colors/palettes/dark_palette.dart';
import 'package:design_system/src/theme/colors/palettes/main_palette.dart';
import 'package:design_system/src/theme/colors/palettes/red_palette.dart';
import 'package:design_system/src/theme/colors/palettes/sky_palette.dart';
import 'package:design_system/src/theme/colors/palettes/yellow_palette.dart';
import 'package:flutter/material.dart';

/// All six Figma palette ramps bundled for theme composition.
@immutable
class AppPalettes {
  const AppPalettes({
    required this.main,
    required this.accent,
    required this.yellow,
    required this.dark,
    required this.sky,
    required this.red,
    required this.white,
    required this.black,
  });

  final ColorScale main;
  final ColorScale accent;
  final ColorScale yellow;
  final ColorScale dark;
  final ColorScale sky;
  final ColorScale red;
  final Color white;
  final Color black;

  static const Color whiteValue = Color(0xFFFFFFFF);
  static const Color blackValue = Color(0xFF000000);

  /// Default light-theme raw palettes — Figma `40:4600`.
  static const AppPalettes light = AppPalettes(
    main: MainPalette.scale,
    accent: AccentPalette.scale,
    yellow: YellowPalette.scale,
    dark: DarkPalette.scale,
    sky: SkyPalette.scale,
    red: RedPalette.scale,
    white: whiteValue,
    black: blackValue,
  );

  /// Same ramp values for dark mode — only semantic mapping differs.
  static const AppPalettes standard = light;

  AppPalettes lerp(AppPalettes other, double t) {
    return AppPalettes(
      main: main.lerp(other.main, t),
      accent: accent.lerp(other.accent, t),
      yellow: yellow.lerp(other.yellow, t),
      dark: dark.lerp(other.dark, t),
      sky: sky.lerp(other.sky, t),
      red: red.lerp(other.red, t),
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
    );
  }
}
