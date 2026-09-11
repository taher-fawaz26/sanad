import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The Requests screen's Figma-exact values — `Requests - Active`
/// (`8135:29516`) and the `CardBody` variants beside it (`8385:4513`,
/// `8385:31894`, `8385:31898`).
///
/// ## Why this file exists
///
/// The design system's six ramps cover most of this screen exactly: the status
/// chips, the meta pills and the "+N" overflow all resolve to real palette
/// steps (verified value-for-value against the Figma variables, see each
/// getter). Reach for `context.appColors` for those — they are **not**
/// duplicated here.
///
/// What is here is the handful of colours the Requests frames take from a
/// neutral grey ramp the Sanad palette does not carry (`#101828`, `#667085`,
/// `#E4E7EC`, `#EAECF0`, `#344054`, `#111827`) plus two accents that sit a few
/// units off their nearest step (`#1A7A66` against `main/700` `#1A7E6B`,
/// `#D12424` against `red/600` `#EE003E`). Choosing the nearest token for
/// those would be picking a colour by eye; writing the Figma value once, here,
/// where it can be read and checked against the design, is the honest version.
///
/// Sizes are Figma's own dp, passed through `responsiveDimension` /
/// `responsiveSpacing` where the design system already has an equal token.
abstract final class ClientRequestsTokens {
  ClientRequestsTokens._();

  // ── Colours the palette does not carry ────────────────────────────────────

  /// Section heading ink — `#111827`.
  static const Color sectionTitle = Color(0xFF111827);

  /// Card title ink — `#101828`.
  static const Color cardTitle = Color(0xFF101828);

  /// Card body / secondary ink — `#667085`.
  static const Color cardBody = Color(0xFF667085);

  /// In-card divider — `#E4E7EC` (the `Line` node's stroke).
  static const Color divider = Color(0xFFE4E7EC);

  /// Unselected tab border — `#EAECF0`.
  static const Color tabBorder = Color(0xFFEAECF0);

  /// Unselected tab label — `#344054`.
  static const Color tabLabel = Color(0xFF344054);

  /// Selected tab fill — `#1A7A66`. Four units off `main/700` (`#1A7E6B`),
  /// which is the token the *label* colours elsewhere on this screen use.
  static const Color tabSelectedFill = Color(0xFF1A7A66);

  /// Destructive outline + label — `#D12424`.
  static const Color danger = Color(0xFFD12424);

  /// The "needs your attention" count badge fill — `rgba(242, 56, 56, 0.12)`.
  static const Color attentionBadgeFill = Color(0x1FF23838);

  /// The green "Open Chat" / "Rebook" affordance — `#127A60`.
  static const Color action = Color(0xFF127A60);

  /// Card elevation — `0 4px 6px rgba(16, 24, 40, 0.03)`. Far softer than any
  /// step on [AppShadows], which starts at 8%: on the mint wash an 8% shadow
  /// reads as a grey halo around every card.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08101828),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  // ── Sizes ─────────────────────────────────────────────────────────────────

  /// Tab pill height — Figma `PillActive` 36.
  static double get tabHeight => responsiveDimension(36);

  /// Tab pill corner — Figma `rounded-[20px]`.
  static double get tabRadius => responsiveDimension(20);

  /// Card corner — Figma `rounded-[16px]`.
  static double get cardRadius => responsiveDimension(16);

  /// Status chip / Cancel button height — Figma 28.
  static double get chipHeight => responsiveDimension(28);

  /// Status chip corner — Figma `rounded-[99px]`, i.e. a stadium.
  static double get chipRadius => responsiveDimension(99);

  /// Cancel / Rebook corner — Figma `rounded-[20px]`.
  static double get buttonRadius => responsiveDimension(20);

  /// Meta pill (date, area) height — Figma 32.
  static double get metaPillHeight => responsiveDimension(32);

  /// Meta pill corner — Figma `rounded-[12px]`.
  static double get metaPillRadius => responsiveDimension(12);

  /// Meta pill glyph — Figma 16.
  static double get metaPillIcon => responsiveDimension(16);

  /// Trailing status badge ("missing address") height — Figma 24.
  static double get badgeHeight => responsiveDimension(24);

  /// "Needs your attention" count badge horizontal padding — Figma
  /// `Badge` (`8385:4389`) px-6.
  static double get attentionBadgePadding => responsiveSpacing(6);

  /// The same badge's vertical padding — Figma py-2.
  static double get attentionBadgePaddingY => responsiveSpacing(2);

  /// The same badge's corner — Figma `rounded-[10px]`.
  static double get attentionBadgeRadius => responsiveDimension(10);
}
