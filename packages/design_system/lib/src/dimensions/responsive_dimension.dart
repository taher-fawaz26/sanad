import 'package:flutter/cupertino.dart' show BuildContext, MediaQuery;
import 'package:flutter/material.dart' show BuildContext, MediaQuery;
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Single-pass clamp-based responsive dimension engine.**
///
/// Used for spatial component sizes: button heights, icon sizes, border radii.
/// Typography sizes use `responsiveFontSize` instead.
///
/// Clamp bounds: [base × 0.90, base × 1.15]  (tighter than spacing — layout
/// elements must not vary as much as gaps to stay pixel-stable).
///
/// O(1) — no [BuildContext], no [MediaQuery].
double responsiveDimension(double base) {
  final scaled = base * ScreenUtil().scaleWidth;
  // Manual branch — no num.clamp() to avoid heap allocation on the hot path.
  final min = base * 0.5;
  final max = base * 2.5;
  if (scaled < min) return min;
  if (scaled > max) return max;
  return scaled;
}

// ─── AppDimension ────────────────────────────────────────────────────────────

/// **Component dimension tokens.**
///
/// Covers button heights, icon bounding boxes and border-radius values.
/// All values are Figma design-spec dp, scaled through [responsiveDimension].
///
/// ### Button heights
/// | Token          | Base (dp) |
/// |----------------|-----------|
/// | `buttonSm`     | 36        |
/// | `buttonMd`     | 48        |
/// | `buttonLg`     | 56        |
/// | `buttonSocial` | 50        |
///
/// ### Icon sizes
/// | Token    | Base (dp) |
/// |----------|-----------|
/// | `icon2xs` | 12       |
/// | `iconXs` | 14        |
/// | `iconSm` | 16        |
/// | `iconMd` | 20        |
/// | `iconLg` | 24        |
///
/// ### Border radii
/// | Token        | Base (dp) |
/// |--------------|-----------|
/// | `radiusXs`   | 6         |
/// | `radiusSm`   | 8         |
/// | `radiusMd`   | 10        |
/// | `radiusLg`   | 12        |
/// | `radiusAlertCard` | 14   |
/// | `radiusXl`   | 24        |
/// | `radiusPill` | 999       |
abstract final class AppDimension {
  AppDimension._();

  // ── Button heights ─────────────────────────────────────────────────────────

  /// 36 dp — small button height.
  static double get buttonSm => responsiveDimension(36);

  /// 48 dp — medium button height (default CTA).
  static double get buttonMd => responsiveDimension(48);

  /// 56 dp — large button height.
  static double get buttonLg => responsiveDimension(56);

  /// 50 dp — social / OAuth pill button height.
  static double get buttonSocial => responsiveDimension(50);

  // ── Icon sizes ─────────────────────────────────────────────────────────────

  /// 12 dp — inline link / map glyph (Figma branch card `4176:4370`).
  static double get icon2xs => responsiveDimension(12);

  /// 14 dp — micro icon (inside labels, badges).
  static double get iconXs => responsiveDimension(14);

  /// 16 dp — compact icons (search bar, chips).
  static double get iconCompact => responsiveDimension(16);

  /// 18 dp — small icon (chevrons, inline field icons).
  static double get iconSm => responsiveDimension(18);

  /// 20 dp — medium icon (social provider logos, form field icons).
  static double get iconMd => responsiveDimension(20);

  /// 22 dp — large icon (button icons, emphasis).
  static double get iconLg => responsiveDimension(22);

  /// 24 dp — menu / nav bar icons.
  static double get iconMenu => responsiveDimension(24);

  // ── Icon button sizes ─────────────────────────────────────────────────────

  /// 28 dp — small icon button (Figma).
  static double get iconButtonSm => responsiveDimension(28);

  /// 40 dp — large icon button (Figma).
  static double get iconButtonLg => responsiveDimension(40);

  // ── Border radii ───────────────────────────────────────────────────────────

  /// 4 dp — badges, tags (Figma extra-small radius).
  static double get radiusXs => responsiveDimension(4);

  /// 8 dp — small rounding (text fields small tier).
  static double get radiusSm => responsiveDimension(8);

  /// 10 dp — medium rounding (text fields medium tier).
  static double get radiusMd => responsiveDimension(12);

  /// 24 dp — large rounding (cards, containers).
  static double get radiusLg => responsiveDimension(24);

  /// 20 dp — compact status pill (Figma `3149:3920` active tickets); also
  /// the segmented-control item radius (Figma `5579:26572`'s "radius-lg" —
  /// note this is a different value than [radiusLg] itself, which is 24 dp).
  static double get radiusTicketPill => responsiveDimension(20);

  /// 16 dp — profile details section cards (Figma `4176:4197`).
  static double get radiusProfileCard => responsiveDimension(16);

  /// 64 dp — profile details empty-state icon ring (Figma `4123:4218`).
  static double get profileEmptyIconRing => responsiveDimension(64);

  /// 28 dp — glyph inside [profileEmptyIconRing].
  static double get profileEmptyIconGlyph => responsiveDimension(28);

  /// 18 dp — language / service tags on profile details.
  static double get radiusProfileTag => responsiveDimension(18);

  /// 14 dp — soft alert cards (Figma `4090:10903`).
  static double get radiusAlertCard => responsiveDimension(14);

  /// 24 dp — extra-large rounding (small buttons).
  static double get radiusXl => responsiveDimension(24);

  /// 32 dp — button pill rounding (medium + large buttons).
  static double get radiusXxl => responsiveDimension(32);

  /// 999 dp — stadium / full-pill shape (social buttons).
  static double get radiusPill => responsiveDimension(999);

  // ── Logo & asset sizes ─────────────────────────────────────────────────────

  /// 150 dp — app logo display size (auth entry screen).
  static double get logoLg => responsiveDimension(150);
  static double get logoMd => responsiveDimension(64);
  static double get logoSm => responsiveDimension(32);

  // ── Fields heights & widths ────────────────────────────────────────────────
  static double get fieldHeightSm => responsiveDimension(36);

  /// Also the segmented-control item height (Figma `5579:26572`).
  static double get fieldHeightMd => responsiveDimension(40);
  static double get fieldHeightLg => responsiveDimension(48);

  /// 45.01 dp — OTP pin cell width/height (Figma `7305:1726` / `7324:7328` /
  /// `7055:27323` — supersedes the older `685:15193` spec).
  static double get otpCellSize => responsiveDimension(45.01);

  /// 13.209 dp — gap between OTP pin cells (same Figma nodes as
  /// [otpCellSize]).
  static double get otpCellGap => responsiveDimension(13.209);

  /// 9.907 dp — OTP pin cell corner radius (same Figma nodes as
  /// [otpCellSize]).
  static double get otpCellRadius => responsiveDimension(9.907);

  /// 1.407 dp — OTP pin cell border width, uniform across empty/filled/error
  /// states — Figma does not thicken the border for the error state (same
  /// Figma nodes as [otpCellSize]).
  static double get otpCellBorderWidth => responsiveDimension(1.407);

  /// Add-service section tabs outer height (Figma `174:9788`).
  static double get segmentedSectionTabsHeight => responsiveDimension(36);

  /// Dropdown chevron size (Figma `174:9807`).
  static double get dropdownChevronSize => responsiveDimension(24);

  static double get fieldWidthSm => responsiveDimension(36);
  static double get fieldWidthMd => responsiveDimension(48);
  static double get fieldWidthLg => responsiveDimension(56);
  static double get fieldWidthXl => responsiveDimension(70);
  static double get fieldWidthXxl => responsiveDimension(80);

  /// Profile hero avatar diameter (Figma `3146:1506` — 96×96).
  static double get profileHeroAvatar => responsiveDimension(96);

  /// Document capture placeholder illustration height.
  static double get documentCaptureIllustrationHeight =>
      responsiveDimension(200);

  /// Upload intro hero SVG (documents flow).
  static double get documentUploadIntroHero => responsiveDimension(192);

  /// Success-state circular badge diameter (upload complete).
  static double get documentUploadSuccessBadge => responsiveDimension(120);

  /// Active step dot in a capture step indicator.
  static double get captureStepDotActive => responsiveDimension(10);

  /// Inactive / completed step dot in a capture step indicator.
  static double get captureStepDotInactive => responsiveDimension(8);

  /// Emphasized card border (e.g. capture illustration frame).
  static double get strokeCard => responsiveDimension(2);

  /// Report issue — gallery tile extent in the image gallery picker.
  static double get reportIssueAttachmentTileExtent => responsiveDimension(90);

  /// Edit service — gallery tile extent (Figma `5817:17103`, 96×100 dp).
  static double get serviceImageGalleryTileExtent => responsiveDimension(96);

  /// Add service — gallery tile width (Figma `174:9816`).
  static double get addServiceGalleryTileWidth => responsiveDimension(86);

  /// Add service — gallery tile height (Figma `174:9816`).
  static double get addServiceGalleryTileHeight => responsiveDimension(80);

  /// Report issue — issue type card icon container diameter.
  static double get reportIssueIssueTypeIconContainer =>
      responsiveDimension(55);

  /// Emergency mode — hero badge outer diameter (Figma `3149:4656`).
  static double get emergencyHeroBadgeDiameter => responsiveDimension(80);

  /// Extra space around hero badge for glow ring.
  static double get emergencyHeroGlowPad => responsiveDimension(24);

  static double get emergencyHeroShadowBlurOuter => responsiveDimension(15);

  static double get emergencyHeroShadowOffsetY => responsiveDimension(10);

  static double get emergencyHeroShadowBlurInner => responsiveDimension(6);

  static double get emergencyHeroInnerShadowSpread => -responsiveDimension(4);

  static double get emergencyHeroStarGlyphWidth => responsiveDimension(26);

  static double get emergencyHeroStarGlyphHeight => responsiveDimension(27);

  /// Emergency service grid — per-art SVG bounds (Figma `3149:4677`).
  static double get emergencyServiceUrgentIconW => responsiveDimension(23);

  static double get emergencyServiceUrgentIconH => responsiveDimension(23);

  static double get emergencyServicePlumbingIconW => responsiveDimension(21);

  static double get emergencyServicePlumbingIconH => responsiveDimension(25);

  static double get emergencyServiceElectricIconW => responsiveDimension(20);

  static double get emergencyServiceElectricIconH => responsiveDimension(25);

  static double get emergencyServiceImmediateIconW => responsiveDimension(25);

  static double get emergencyServiceImmediateIconH => responsiveDimension(23);

  /// Emergency service grid tile width/height ratio.
  static const double emergencyServiceGridTileAspectRatio = 1.08;

  /// Notification list — leading icon plate (Figma 48×48, matches `buttonMd`).
  static double get notificationCardLeadingSize => buttonMd;

  /// Notification list — unread badge diameter (Figma 8 dp).
  static double get notificationCardUnreadDot => captureStepDotInactive;

  /// Ratings hub — review card outer inset (Figma ~17 dp).
  static double get ratingsReviewCardInset => responsiveDimension(17);

  /// Ratings hub — compact star icon in review row (Figma ~13.33 dp).
  static double get ratingsReviewStarIcon => responsiveDimension(13.333);

  /// Ratings hub — reviewer avatar diameter (40 dp).
  static double get ratingsReviewAvatar => responsiveDimension(40);

  /// Hairline border width (1 dp), e.g. thin card outlines.
  static double get borderHairline => responsiveDimension(1);

  /// Segmented control track horizontal padding — direction-independent
  /// (Figma `5579:26572`, `5579:25923`).
  static double get controlTrackPaddingHorizontal => responsiveDimension(6);

  /// Search bar cancel action area width (`40:6999`).
  static double get searchCancelAreaWidth => responsiveDimension(69);

  /// Full-width chip / search field width (`40:7367`, `40:6999`).
  static double get contentMaxWidth => responsiveDimension(327);

  /// Table row height (`40:9256`).
  static double get tableRowHeight => responsiveDimension(64);

  /// Notification badge diameter (`40:10681`).
  static double get notificationBadgeSize => responsiveDimension(18);
}
