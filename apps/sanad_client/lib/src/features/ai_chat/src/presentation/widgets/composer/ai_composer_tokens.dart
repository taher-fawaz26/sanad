import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Colors the AI Chat surface takes straight from its own Figma page rather
/// than from the app's semantic roles.
///
/// Every value here resolves to a shade that already exists in the design
/// system's palettes — nothing is a new hex. What differs is only *which*
/// shade the AI screens use, and this is deliberately a client-local lookup
/// rather than a change to `AppColors`: repointing a semantic role like
/// `primary` would restyle every other screen in both apps to fix one.
///
/// See [accent] for the one that actually differs; the rest are named here so
/// the composer reads its fills from a single documented place instead of
/// spreading `palettes.dark.shadeN` lookups through the widget tree.
abstract final class AiComposerTokens {
  AiComposerTokens._();

  /// The AI surface's green — Figma `#1A7E6B` (`MainPalette.shade700`), used
  /// for the focused card border, the typing caret, the Send pill and the
  /// dictation transcript.
  ///
  /// Not `AppColors.primary`, which is `MainPalette.shade600` (`#26A68C`) —
  /// a visibly lighter, more saturated green. The AI Chat page consistently
  /// specifies the darker shade700 across every state in
  /// `Sanad AI Input` (`7827:30542`), so following `primary` here would miss
  /// the design on the composer's most prominent element.
  static Color accent(BuildContext context) =>
      context.appColors.palettes.main.shade700;

  /// Fill behind the composer's circular controls — Figma `#F3F4F6`, which
  /// the design system carries as `controlFill` (`DarkPalette.shade100`,
  /// `#F2F3F3`).
  static Color controlFill(BuildContext context) =>
      context.appColors.controlFill;

  /// The live-voice glyph's bars — Figma `#575B5E`, exactly
  /// `DarkPalette.shade600`, which the theme already exposes as
  /// `textSecondary`.
  static Color glyph(BuildContext context) => context.appColors.textSecondary;
}
