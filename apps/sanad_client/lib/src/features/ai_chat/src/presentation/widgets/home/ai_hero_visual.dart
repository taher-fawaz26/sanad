import 'dart:math' as math;

import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The hero mark itself — Figma `Frame 427319459` (`7118:29598`): the green
/// bloom with Sanad's sparkle riding on it, which together read as one
/// visual.
///
/// ## Two halves, two sources
///
/// The **bloom is Figma's own `bg` node** ([AppImages.aiChatHeroBloom],
/// `8245:35005`) — two blurred gradient shapes, exported as a transparent
/// raster because `flutter_svg` cannot render the `feGaussianBlur` they are
/// built from.
///
/// It used to be a Lottie, which animated itself: a rotating aura ring behind
/// an orb, looping every 5s. The design's motion for this node is not that.
/// It is a four-second *breathe* — scale 1 → 1.02 → 1 and opacity 85% → 100%
/// → 85%, eased `cubic-bezier(0.42, 0, 0.58, 1)` between each keyframe — and
/// a still image under [AppBreathe] reproduces it exactly, where a
/// self-animating composition could only have it layered on top of a second
/// rhythm. `AppLottie` and its asset are untouched and still serve the
/// loaders they were built for; this surface simply no longer needs one.
///
/// The **mark is not part of the bloom**, and the breathe is not applied to
/// it: the spec's subject is the background, and fading the logo to 85% would
/// be a change to the logo. [AppSvgs.aiChatHeroMark] is the node's exact
/// asset, at the node's exact geometry, unchanged.
///
/// [AppBreathe] keeps the reduced-motion contract (frozen to frame one, since
/// this is identity rather than progress) and its own `RepaintBoundary`.
class AiHeroVisual extends StatelessWidget {
  /// Creates the hero.
  const AiHeroVisual({super.key});

  /// Figma's hero frame is 200dp square, with the mark at ~93.8 x 91.8
  /// centred and nudged 6.95dp above centre (`7118:29600`).
  static const _markWidth = 93.77;
  static const _markHeight = 91.82;
  static const _markOffsetY = -6.95;

  /// The box this visual occupies in the page's layout, and the size the
  /// bloom is drawn at inside it.
  ///
  /// [_bloomSize] is deliberately the same 280 the Lottie composition was
  /// given, so swapping the asset moves nothing around it. [_bloomAssetSize]
  /// is the export's own 267 — Figma's 200dp `bg` frame plus the 33.5 per
  /// side its blur bleeds past it — which lands the painted glow at the same
  /// ~266dp of content the Lottie was measured to produce, and at Figma's own
  /// mark-to-bloom ratio (93.8 / 267). Everything painted still fits inside
  /// the box, so nothing is clipped and only dead margin falls outside.
  static const _bloomSize = 280.0;
  static const _bloomAssetSize = 267.0;

  /// Figma applies a 179.66° rotation to the mark inside this node.
  static const double _markTurns = 179.66 / 360;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _bloomSize,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Decorative: the accessible copy for this surface is the greeting
        // beside it, and the bloom itself says nothing a screen reader needs.
        ExcludeSemantics(
          child: AppBreathe(
            child: Image.asset(
              AppImages.aiChatHeroBloom,
              package: AppAssets.package,
              width: _bloomAssetSize,
              height: _bloomAssetSize,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, _markOffsetY),
          child: Transform.rotate(
            angle: _markTurns * 2 * math.pi,
            child: SvgPicture.asset(
              AppSvgs.aiChatHeroMark,
              package: AppAssets.package,
              width: _markWidth,
              height: _markHeight,
            ),
          ),
        ),
      ],
    ),
  );
}
