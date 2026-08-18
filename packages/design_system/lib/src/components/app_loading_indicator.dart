import 'package:app_assets/app_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

// ─── AppLoadingIndicator ───────────────────────────────────────────────────

/// App-wide loading spinner — a SANAD green fading-ring Lottie animation.
///
/// Fixed brand colors (`MainPalette.shade500`/`shade100`, baked into the
/// asset), not theme-derived, so it reads the same in light and dark mode.
///
/// ### Usage
/// ```dart
/// const AppLoadingIndicator()
/// ```
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 48});

  /// Width and height of the indicator.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: Lottie.asset(
        AppAnimations.appLoadingIndicator,
        package: AppAssets.package,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
