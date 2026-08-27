import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Circular floating action button (e.g. "add service").
///
/// Sourced from [ButtonTokens] (`variant: primary, intent: standard`) — the
/// same resolver [AppButton] uses. `AppButtonVariant.primary`'s default fill
/// intentionally has no light/dark fork, so the button reads consistently in
/// either theme, same as before this was tokenized.
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
    final surface = ButtonTokens.resolve(
      variant: AppButtonVariant.primary,
      colors: colors,
      brightness: Theme.of(context).brightness,
      states: const {},
    );
    final backgroundColor = surface.background;

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
            child: Icon(icon, color: surface.foreground, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
