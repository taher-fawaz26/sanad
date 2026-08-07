import 'dart:ui' as ui;

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Interpolates the Sanad logo between expanded-hero and collapsed-toolbar
/// states from a single [collapseProgress] value.
///
/// When [collapsedTitle] is provided the collapsed toolbar lays out as:
/// `[Back leading slot] [Logo] [Spacing] [Title]`
///
/// The logo completes its move during the first 60% of collapse; the title
/// fades in only during the last 40% (iOS large-title style).
class RegistrationLogo extends StatelessWidget {
  const RegistrationLogo({
    required this.collapseProgress,
    this.collapsedTitle,
    this.reserveLeadingSpace = false,
    super.key,
  });

  /// `1.0` expanded → `0.0` collapsed.
  final double collapseProgress;

  /// Optional page title shown beside the logo once the bar has collapsed.
  final String? collapsedTitle;

  /// When true, collapsed logo/title start after the [SliverAppBar] leading
  /// width (back button slot).
  final bool reserveLeadingSpace;

  static const _largeWidth = 225.0;
  static const _largeHeight = 73.0;

  /// Slightly smaller than legacy 90×29 to leave room for localized titles.
  static const _smallWidth = 72.0;
  static const _smallHeight = 23.0;

  /// Logo reaches the toolbar row after the first 60% of collapse (`t` ≤ 0.4).
  static const _logoSettleThreshold = 0.4;

  /// Title fades in during the last 40% of collapse (`t` ≤ 0.4 → 0).
  static const _titleRevealThreshold = 0.4;

  /// How far through collapse the logo has moved into the toolbar (`0` → `1`).
  @visibleForTesting
  static double logoToolbarBlend(double collapseProgress) {
    final t = collapseProgress.clamp(0.0, 1.0);
    if (t <= _logoSettleThreshold) return 1;
    return ((1 - t) / (1 - _logoSettleThreshold)).clamp(0.0, 1.0);
  }

  /// Title opacity — zero until the final 40% of collapse.
  @visibleForTesting
  static double collapsedTitleOpacity(double collapseProgress) {
    final t = collapseProgress.clamp(0.0, 1.0);
    if (t > _titleRevealThreshold) return 0;
    return ((_titleRevealThreshold - t) / _titleRevealThreshold).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = collapseProgress.clamp(0.0, 1.0);
    final topPadding = MediaQuery.paddingOf(context).top;
    final toolbarBlend = logoToolbarBlend(t);
    final titleOpacity = collapsedTitle != null
        ? collapsedTitleOpacity(t)
        : 0.0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final leadingWidth = reserveLeadingSpace ? kToolbarHeight : 0.0;
    final spacing = responsiveDimension(AppSpacing.md);
    final edgeInset = responsiveDimension(AppSpacing.sm);

    return LayoutBuilder(
      builder: (context, constraints) {
        final smallLogoWidth = responsiveDimension(_smallWidth);
        final smallLogoHeight = responsiveDimension(_smallHeight);
        final largeLogoWidth = responsiveDimension(_largeWidth);
        final largeLogoHeight = responsiveDimension(_largeHeight);

        final logoWidth = ui.lerpDouble(
          smallLogoWidth,
          largeLogoWidth,
          1 - toolbarBlend,
        )!;
        final logoHeight = ui.lerpDouble(
          smallLogoHeight,
          largeLogoHeight,
          1 - toolbarBlend,
        )!;

        final expandedCenterX = constraints.maxWidth / 2;
        final expandedCenterY = constraints.maxHeight / 2;

        final collapsedLogoCenterX = isRtl
            ? constraints.maxWidth -
                  leadingWidth -
                  edgeInset -
                  smallLogoWidth / 2
            : leadingWidth + edgeInset + smallLogoWidth / 2;

        final collapsedCenterY = topPadding + kToolbarHeight / 2;

        final logoCenterX = ui.lerpDouble(
          expandedCenterX,
          collapsedLogoCenterX,
          toolbarBlend,
        )!;
        final logoCenterY = ui.lerpDouble(
          expandedCenterY,
          collapsedCenterY,
          toolbarBlend,
        )!;

        final titleLeft = isRtl
            ? edgeInset
            : leadingWidth + smallLogoWidth + spacing;
        final titleRight = isRtl
            ? leadingWidth + smallLogoWidth + spacing
            : edgeInset;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: logoCenterX - logoWidth / 2,
              top: logoCenterY - logoHeight / 2,
              width: logoWidth,
              height: logoHeight,
              child: AppSvgPicture.asset(
                AppSvgs.sanadLogo,
                width: logoWidth,
                height: logoHeight,
              ),
            ),
            if (collapsedTitle != null && titleOpacity > 0)
              Positioned(
                left: titleLeft,
                right: titleRight,
                top: topPadding,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: titleOpacity,
                  child: Align(
                    alignment: isRtl
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      collapsedTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: context.appTypography.regularNormal.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
