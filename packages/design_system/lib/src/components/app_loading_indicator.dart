import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ─── AppLoadingIndicator ───────────────────────────────────────────────────

/// App-wide loading spinner — a [SpinKitFadingCircle] in the brand primary
/// color.
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
    return SizedBox.square(
      dimension: size,
      child: SpinKitFadingCircle(
        color: context.appColors.primary,
        size: size,
      ),
    );
  }
}
