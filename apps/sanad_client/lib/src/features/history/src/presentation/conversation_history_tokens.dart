import 'package:flutter/widgets.dart';

/// The measurements Conversation History takes straight from its own Figma
/// frames (`8120:2918` populated, `8124:3867` empty).
///
/// Client-local, following the `AiComposerTokens` / `ClientGlassTokens`
/// precedent: these are the numbers of two screens, not a new tier in the
/// shared spacing or radius scales, and adding steps to those scales to hold
/// them would offer every other screen in both apps a size the design system
/// never specified.
///
/// Only values with **no** design-system token live here. Everything that maps
/// cleanly — the 20dp page inset (`AppSpacing.xl`), the 16dp card padding
/// (`AppSpacing.lg`), the 12dp gaps (`AppSpacing.md`), the 48dp CTA
/// (`AppButtonSize.block`) — is read from the tokens at the point of use
/// instead of being restated here.
abstract final class ConversationHistoryTokens {
  ConversationHistoryTokens._();

  // ── Search field (`8102:35060`) ─────────────────────────────────────────

  /// Field height. Taller than `AppDimension.fieldHeightMd` (40dp), which is
  /// what the shared search bar resolves for every other screen.
  static const double searchHeight = 52;

  /// Corner radius. Falls between `AppDimension.radiusMd` (12) and
  /// `radiusLg` (24).
  static const double searchRadius = 16;

  /// Inset from the field's edge to the search glyph, and from the text to
  /// the trailing edge.
  static const double searchIconPadding = 12;

  /// Glyph-to-text gap. One dp under `AppSpacing.md`.
  static const double searchIconGap = 10;

  /// Glyph size — Figma's 20dp export, not the shared bordered variant's
  /// 22dp (`AppDimension.iconLg`).
  static const double searchIconSize = 20;

  /// Placeholder and value size. `AppSpacing`-free because it is type, not
  /// space: 14dp is the design system's `small` tier, and the style itself is
  /// built from `AppTypography.smallNormal` at the call site.
  static const double searchFontSize = 14;

  // ── History card (`8102:35064`) ────────────────────────────────────────

  /// Card corner radius. Between `radiusMd` (12) and `radiusLg` (24), like
  /// [searchRadius] but a step larger.
  static const double cardRadius = 20;

  /// The leading Sanad sparkle's box on the header row.
  static const double cardGlyphSize = 16;

  /// How many lines of preview text a card shows before ellipsizing. Figma
  /// draws every card at two lines; a third would let one conversation push
  /// the rest of the list off the screen.
  static const int cardPreviewMaxLines = 2;

  // ── Empty state (`8124:3831`) ──────────────────────────────────────────

  /// The illustration's square, centred in the page.
  static const double emptyIllustrationSize = 220;

  /// The pale outer bloom's diameter (`8124:3833`).
  static const double emptyBloomSize = 180;

  /// The white disc's diameter (`8124:3834`), drawn as a 140dp circle in a
  /// 160dp export whose extra 20dp is the drop shadow's own bleed.
  static const double emptyDiscSize = 140;

  /// The chat glyph's render size — `AppSvgs.aiChatHistoryEmptyChat`'s own
  /// intrinsic size, which is Figma's 38.3629 glyph plus its 2.6765 stroke
  /// bleed.
  static const double emptyGlyphSize = 41.0394;

  /// Alpha of the outer bloom: Figma stacks a 10% `#26A68C` fill inside a
  /// layer at 55% opacity, which multiplies out to this.
  static const double emptyBloomAlpha = 0.1 * 0.55;

  /// The white disc's drop shadow — Figma's `dy 4`, `stdDeviation 5` (a
  /// Gaussian sigma, so twice it as a Flutter blur radius) over the design
  /// system's own `#141414` shadow ink at 4%.
  ///
  /// Not one of `AppShadows`' three steps: all of those are centred
  /// (`offset: Offset.zero`, bar a 1dp nudge) and this one is offset far
  /// enough to read as a disc lifted off the page rather than a glow around
  /// it.
  static const List<BoxShadow> emptyDiscShadow = [
    BoxShadow(
      color: Color(0x0A141414),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Empty-state description size. Between the design system's `small` (14)
  /// and `regular` (16) tiers, with a 26dp line height neither carries.
  static const double emptyDescriptionFontSize = 15;

  /// Line height for the empty-state description, as a multiple of
  /// [emptyDescriptionFontSize].
  static const double emptyDescriptionHeight = 26 / 15;

  /// Top inset of the empty-state block (`pt-[72px]`).
  static const double emptyPaddingTop = 72;

  /// Bottom inset of the empty-state block (`pb-[56px]`).
  static const double emptyPaddingBottom = 56;
}
