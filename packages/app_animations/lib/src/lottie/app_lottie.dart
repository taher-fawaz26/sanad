import 'package:app_animations/src/lottie/app_lottie_asset.dart';
import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_assets/app_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart' as lottie;

/// The single Lottie abstraction — every animated illustration/loader in the
/// app renders through this widget. No feature or design-system code should
/// import `package:lottie/lottie.dart` directly (enforced by
/// `dep_rules.yaml`'s `lottie_allowed_packages`).
///
/// Always wrapped in a [RepaintBoundary] (isolates the animation's repaints
/// from its surrounding tree) and `Semantics(excludeSemantics: true)`
/// (purely decorative pixels — the caller supplies the real accessible copy
/// alongside it).
///
/// [isDecorative] controls reduced-motion behavior:
/// - `false` (default, used by [AppLottie.loading]/[AppLottie.documentExtraction]):
///   the animation communicates active work — it keeps playing even when
///   [AppMotion.reduceMotionOf] is true, matching the platform convention
///   that functional progress indicators are never suppressed.
/// - `true` (used by [AppLottie.notFound]/[AppLottie.forbidden]): purely
///   decorative illustrations — frozen to their first frame under reduced
///   motion.
class AppLottie extends StatelessWidget {
  /// Creates a Lottie animation for [asset].
  const AppLottie({
    required this.asset,
    super.key,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.isDecorative = false,
  });

  /// App-wide loading spinner. Functional — never frozen by reduced motion.
  factory AppLottie.loading({Key? key, double size = 48}) {
    return AppLottie(key: key, asset: AppLottieAsset.loading, size: size);
  }

  /// Document-extraction loading state. Functional — never frozen by
  /// reduced motion; kept in the tree by callers so it's never recreated
  /// (and never restarts) by unrelated rebuilds.
  factory AppLottie.documentExtraction({Key? key, double size = 300}) {
    return AppLottie(
      key: key,
      asset: AppLottieAsset.documentExtraction,
      size: size,
    );
  }

  /// "404 Not Found" illustration. Decorative — frozen under reduced motion.
  factory AppLottie.notFound({required double size, Key? key}) {
    return AppLottie(
      key: key,
      asset: AppLottieAsset.notFound,
      size: size,
      isDecorative: true,
    );
  }

  /// "403 Forbidden" illustration. Decorative — frozen under reduced motion.
  factory AppLottie.forbidden({required double size, Key? key}) {
    return AppLottie(
      key: key,
      asset: AppLottieAsset.forbidden,
      size: size,
      isDecorative: true,
    );
  }

  /// Which animation to play.
  final AppLottieAsset asset;

  /// Convenience: sets both [width] and [height] to a single square
  /// dimension. Ignored if [width]/[height] are set explicitly.
  final double? size;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Whether the animation loops. Explicit — never left to the package
  /// default, per the app's Lottie performance rules.
  final bool repeat;

  /// See the class doc for the reduced-motion contract this controls.
  final bool isDecorative;

  @override
  Widget build(BuildContext context) {
    final frozen = isDecorative && AppMotion.reduceMotionOf(context);

    return Semantics(
      excludeSemantics: true,
      child: RepaintBoundary(
        child: lottie.Lottie.asset(
          asset.path,
          package: AppAssets.package,
          width: width ?? size,
          height: height ?? size,
          fit: fit,
          animate: !frozen,
          repeat: !frozen && repeat,
        ),
      ),
    );
  }
}
