import 'package:app_animations/app_animations.dart';
import 'package:flutter/widgets.dart';

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
    return AppLottie.loading(size: size);
  }
}
