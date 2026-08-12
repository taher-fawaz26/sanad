import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Circular floating action button (e.g. "add service").
///
/// Background is the brand teal `#26A68C` — [AppPalettes.main]'s `shade600`
/// step — fixed across light/dark themes (unlike [AppColors.primary], which
/// remaps per brightness) so the button reads consistently in either mode.
class AppFloatingActionButton extends StatelessWidget {
  /// Creates a floating action button.
  const AppFloatingActionButton({
    required this.onPressed,
    this.icon = Icons.add_circle_outline_rounded,
    this.semanticLabel,
    this.size = 56,
    super.key,
  });

  /// Invoked on tap.
  final VoidCallback onPressed;

  /// Icon shown at the center, tinted white.
  final IconData icon;

  /// Accessibility label announced for this button.
  final String? semanticLabel;

  /// Diameter of the circular button.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final backgroundColor = colors.palettes.main.shade600;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: colors.palettes.white, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
