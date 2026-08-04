import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma `Enhance with AI` pill button (`3233:17332`).
///
/// Design reference: `lib/src/shared_ui/enhance_with_ai.svg`.
///
/// The border uses a rainbow conic gradient. `flutter_svg` cannot render the
/// CSS `conic-gradient` inside the SVG's `<foreignObject>`, so the gradient
/// is reproduced via [SweepGradient] while the sparkle icon and [label] are
/// rendered as Flutter widgets.
class AppEnhanceWithAiButton extends StatelessWidget {
  const AppEnhanceWithAiButton({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  // Mirrors conic-gradient(from 90deg, #0b8fff 0deg, #98c6ff 111.992deg,
  // #fff 228.521deg, #fff 279.876deg, #02b35b 323.24deg, #ffce00 333.176deg,
  // #ff3c2b 348.538deg, #0b8fff 360deg) from the SVG.
  static final _borderGradient = SweepGradient(
    startAngle: -math.pi / 2,
    endAngle: 3 * math.pi / 2,
    colors: const [
      Color(0xFF0B8FFF),
      Color(0xFF98C6FF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFF02B35B),
      Color(0xFFFFCE00),
      Color(0xFFFF3C2B),
      Color(0xFF0B8FFF),
    ],
    stops: const [0.0, 0.311, 0.635, 0.777, 0.898, 0.925, 0.968, 1.0],
  );

  // #26A68C — the sparkle color from the SVG
  static const _sparkleColor = Color(0xFF26A68C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 41,
        decoration: BoxDecoration(
          gradient: _borderGradient,
          borderRadius: BorderRadius.circular(20.5),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: _sparkleColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
