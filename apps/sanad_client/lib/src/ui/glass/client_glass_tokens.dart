import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// How much of the page shows through a glass surface.
///
/// Three levels rather than free parameters, because the point of a glass
/// *system* is that two surfaces at the same depth look the same. A caller
/// picks what the surface is; it does not pick a blur radius.
enum ClientGlassLevel {
  /// Chrome that floats over scrolling content — the Home header's nav pill
  /// and its round buttons. The lightest treatment: this sits over a moving
  /// background, so it blurs least and tints most.
  nav,

  /// A resting panel the user reads and types into — the composer card. Tinted
  /// hardest of the three, because a text field has to stay readable over
  /// whatever the page puts behind it.
  surface,

  /// Something lifted clear of the page. The most blur and the least tint, so
  /// the separation is obvious.
  floating,
}

/// The values behind [ClientGlassLevel].
///
/// Client-local, following the `AiComposerTokens` precedent: this is a visual
/// language for the client's AI surfaces, not a change to the shared design
/// system, and repointing a shared token would restyle the provider app to
/// solve a problem it does not have. Every colour still resolves from
/// `context.appColors` — nothing here is a new hex.
abstract final class ClientGlassTokens {
  ClientGlassTokens._();

  /// Blur radius, in logical pixels.
  ///
  /// Deliberately modest. Sigma is the expensive half of a `BackdropFilter` and
  /// the returns fall off quickly: past roughly 24 the surface reads as opaque
  /// frosted plastic and stops looking like glass at all.
  static double sigmaFor(ClientGlassLevel level) => switch (level) {
    ClientGlassLevel.nav => 16,
    ClientGlassLevel.surface => 20,
    ClientGlassLevel.floating => 24,
  };

  /// The wash over the blur.
  ///
  /// High enough that `textPrimary` clears WCAG AA over the darkest thing the
  /// AI background puts behind these surfaces — Figma's `#C9FBD8` mint at the
  /// bottom of the wash, which is where the composer actually sits. The
  /// composer is tinted hardest for exactly that reason: it is the one glass
  /// surface a user reads a sentence off.
  static Color tintFor(BuildContext context, ClientGlassLevel level) =>
      context.appColors.surface.withValues(
        alpha: switch (level) {
          ClientGlassLevel.nav => 0.62,
          ClientGlassLevel.surface => 0.80,
          ClientGlassLevel.floating => 0.55,
        },
      );

  /// The hairline that gives the surface an edge.
  ///
  /// Without it a translucent panel has no boundary and dissolves into the
  /// gradient behind it, which is the failure mode that makes glass read as
  /// "unfinished" rather than "layered".
  static Color borderFor(BuildContext context) =>
      context.appColors.surface.withValues(alpha: 0.45);

  /// The highlight along the top edge, mimicking light catching a bevel.
  static Color highlightFor(BuildContext context) =>
      context.appColors.surface.withValues(alpha: 0.35);

  /// The shadow that separates the surface from the page.
  ///
  /// Softer and shorter than [AppShadows.small]: a translucent surface with a
  /// heavy drop shadow reads as a sticker rather than as glass.
  static List<BoxShadow> shadowFor(
    BuildContext context,
    ClientGlassLevel level,
  ) => [
    BoxShadow(
      color: context.appColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: level == ClientGlassLevel.nav ? 12 : 16,
      offset: const Offset(0, 4),
    ),
  ];
}
