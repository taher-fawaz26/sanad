import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// The measurements the AI card language takes straight from its own Figma
/// frame (`7998:34166`), for the values the design system has no token for.
///
/// Companion to `AiUiTokens`, which maps *protocol vocabulary* onto design
/// tokens. This file holds the other half: shapes that are specific to the AI
/// surface and would be wrong as new steps in the shared radius or spacing
/// scales, because no other screen in either app asks for them.
///
/// Every **colour** still resolves from `context.appColors` — nothing here is
/// a new hex. Where Figma's literal and the nearest token differ, the token
/// wins and the reason is recorded on the member.
abstract final class AiCardTokens {
  AiCardTokens._();

  // ── Card shell ────────────────────────────────────────────────────────────

  /// Corner radius of every AI card. Falls between `AppDimension.radiusMd`
  /// (12) and `radiusLg` (24), which is why it is stated here.
  static double get cardRadius => responsiveDimension(16);

  /// The `request_summary` shell, which Figma draws one step rounder and with
  /// a lift the other cards do not have.
  static double get panelRadius => responsiveDimension(24);

  /// Figma `shadow-[0_8px_24px_rgba(0,0,0,0.04)]` on the `request_summary`
  /// panel. Not one of `AppShadows`' three steps: all of those are centred,
  /// and this one is offset far enough to read as a lifted panel.
  static List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: const Color(0x0A141414),
      blurRadius: responsiveDimension(24),
      offset: Offset(0, responsiveDimension(8)),
    ),
  ];

  /// Border width on a card the design calls out — a selected `service_card`,
  /// a `reminder_card`. Figma uses 1.5 against the default hairline's 1.
  static const double emphasisBorderWidth = 1.5;

  // ── Inner shapes ──────────────────────────────────────────────────────────

  /// The rounded value tiles inside a `request_summary`, and the comment box
  /// inside a `review_request`. Exactly `AppDimension.radiusMd`, named here so
  /// the intent reads at the call site.
  static double get tileRadius => AppDimension.radiusMd;

  /// Option rows in the prompt cards — `media_request`, `location_picker`.
  static double get optionRadius => responsiveDimension(18);

  /// A status badge's corner. Tighter than `AppDimension.radiusSm` (8).
  static double get badgeRadius => responsiveDimension(6);

  /// The address box on `location_confirm`.
  static double get addressRadius => responsiveDimension(14);

  /// Diameter of the tinted disc that leads a `payment_receipt` or
  /// `reminder_card` header.
  static double get discSize => responsiveDimension(40);

  /// The glyph inside [discSize].
  static double get discGlyphSize => AppDimension.iconMd;

  /// The provider avatar.
  static double get avatarSize => responsiveDimension(48);

  /// A card's own picture, when the agent attaches one. Matches the
  /// `wide`-aspect proportion the `image` primitive uses at card width.
  static double get thumbHeight => responsiveDimension(140);

  /// Leading glyph on an inline detail row — the calendar and pin on an
  /// appointment, the pin on a branch.
  static double get rowGlyphSize => AppDimension.iconCompact;

  /// The star beside a rating value.
  static double get starSize => responsiveDimension(14);

  // ── Controls ──────────────────────────────────────────────────────────────

  /// Height of a button in a card's attached action row. Shorter than
  /// `AppButtonSize.block`'s 48 because it sits inside a card, not under one.
  static double get cardButtonHeight => responsiveDimension(44);

  /// A button that shares a row with content rather than owning its own —
  /// Figma's `Select` pill on a `service_card`'s price row.
  static double get inlineButtonHeight => responsiveDimension(34);

  /// Corner of a card action button. Fully rounded at [cardButtonHeight].
  static double get cardButtonRadius => responsiveDimension(32);

  /// Height of the full-width CTA on a prompt card, matching
  /// `AppButtonSize.block`.
  static double get promptButtonHeight => responsiveDimension(48);

  /// Height of a selectable slot chip.
  static double get slotHeight => responsiveDimension(40);

  /// Slots per row in a `time_slots` grid.
  static const int slotColumns = 2;

  /// Height of a `review_request` comment box.
  static double get commentBoxHeight => responsiveDimension(150);

  /// Height of the map preview on the location prompts.
  static double get mapPreviewHeight => responsiveDimension(120);

  /// Figma draws the map at 60% so it reads as an illustration rather than a
  /// live map the user could pan.
  static const double mapPreviewOpacity = 0.6;
}
