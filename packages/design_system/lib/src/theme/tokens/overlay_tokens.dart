import 'package:flutter/material.dart';

/// Native-chrome / overlay color tokens shared by the overlay component
/// family — [AppBottomSheet], [AppActionSheet], [AppBackdrop] — and the
/// shared drag-handle indicator.
///
/// Figma defines a distinct "Ink" / "Sky (chrome)" variable collection for
/// these native-chrome surfaces, separate from the [DarkPalette]/[SkyPalette]
/// hue ramps used for semantic UI colors. Sourced from:
/// - `_Partials/Overlay` (`40:8737`) — scrim
/// - `Native/Bottom Sheet Indicator` (`40:8321`) — drag handle
/// - `Views/Action Sheets` (`40:9109`)
/// - `Views/Bottom Sheets` (`40:9140`)
abstract final class OverlayTokens {
  OverlayTokens._();

  // Ink scale — 4 steps confirmed from Figma overlay components
  // (40:8737, 40:8321, 40:9109, 40:9140). Extend if more steps are
  // referenced by future components.
  static const Color ink900 = Color(0xFF090A0A); // Ink/Darkest
  static const Color ink800 = Color(0xFF202325); // Ink/Darker
  static const Color ink700 = Color(0xFF303437); // Ink/Dark
  static const Color ink600 = Color(0xFF6C7072); // Ink/Light

  // Native-chrome grays confirmed from Figma (distinct from SkyPalette hue
  // ramp).
  static const Color chromeBase = Color(0xFFCDCFD0); // Sky/Base
  static const Color chromeLighter = Color(0xFFF2F4F5); // Sky/Lighter
  static const Color chromeDark = Color(0xFF979C9E); // Sky/Dark

  static const double scrimOpacity = 0.7;

  /// Scrim color shown behind modal overlays (`_Partials/Overlay`, `40:8737`).
  static Color scrimColor() => ink900.withValues(alpha: scrimOpacity);
}
