import 'package:flutter/material.dart';

/// A single Figma color ramp — shades **50** through **950**.
///
/// Source: Figma `design-system-sanad` → section `color` (`40:4600`).
@immutable
class ColorScale {
  const ColorScale({
    required this.shade50,
    required this.shade100,
    required this.shade200,
    required this.shade300,
    required this.shade400,
    required this.shade500,
    required this.shade600,
    required this.shade700,
    required this.shade800,
    required this.shade900,
    required this.shade950,
  });

  final Color shade50;
  final Color shade100;
  final Color shade200;
  final Color shade300;
  final Color shade400;
  final Color shade500;
  final Color shade600;
  final Color shade700;
  final Color shade800;
  final Color shade900;
  final Color shade950;

  /// Returns the shade for [step] — one of `50, 100, …, 950`.
  Color operator [](int step) => switch (step) {
    50 => shade50,
    100 => shade100,
    200 => shade200,
    300 => shade300,
    400 => shade400,
    500 => shade500,
    600 => shade600,
    700 => shade700,
    800 => shade800,
    900 => shade900,
    950 => shade950,
    _ => throw ArgumentError.value(step, 'step', 'Invalid palette step'),
  };

  ColorScale lerp(ColorScale other, double t) {
    return ColorScale(
      shade50: Color.lerp(shade50, other.shade50, t)!,
      shade100: Color.lerp(shade100, other.shade100, t)!,
      shade200: Color.lerp(shade200, other.shade200, t)!,
      shade300: Color.lerp(shade300, other.shade300, t)!,
      shade400: Color.lerp(shade400, other.shade400, t)!,
      shade500: Color.lerp(shade500, other.shade500, t)!,
      shade600: Color.lerp(shade600, other.shade600, t)!,
      shade700: Color.lerp(shade700, other.shade700, t)!,
      shade800: Color.lerp(shade800, other.shade800, t)!,
      shade900: Color.lerp(shade900, other.shade900, t)!,
      shade950: Color.lerp(shade950, other.shade950, t)!,
    );
  }
}
