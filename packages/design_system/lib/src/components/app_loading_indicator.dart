import 'package:app_assets/app_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─── AppLoadingIndicator ───────────────────────────────────────────────────

/// Frame-by-frame loading animation driven by an [AnimationController].
///
/// Sprite frame paths are generated automatically from [frameCount],
/// [assetFolder], and [assetPrefix] — for example the defaults produce:
///
/// ```plaintext
/// assets/lottie/sprite_0000.png
/// assets/lottie/sprite_0001.png
/// …
/// assets/lottie/sprite_0008.png
/// ```
///
/// Animation speed is controlled solely by [duration] — one full cycle
/// displays every frame once.
///
/// ### Usage
/// ```dart
/// const AppLoadingIndicator()
/// ```
///
/// ### Custom frame count
/// ```dart
/// AppLoadingIndicator(frameCount: 36)
/// ```
///
/// ### Performance notes
/// - Uses [AnimatedBuilder] so only the image layer rebuilds when the frame
///   index changes.
/// - [Image.asset] is called with `gaplessPlayback: true` to avoid flicker
///   between consecutive frames.
/// - The [AnimationController] is disposed in [State.dispose].
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 48,
    this.duration = const Duration(milliseconds: 500),
    this.frameCount = 7,
    this.assetFolder = 'assets/lottie',
    this.assetPrefix = 'sprite_',
    this.package = AppAssets.package,
    this.fit = BoxFit.contain,
  }) : assert(frameCount > 0, 'frameCount must be greater than 0');

  /// Width and height of the indicator.
  final double size;

  /// Duration of one full animation cycle (all frames shown once).
  final Duration duration;

  /// Number of sprite frames (`0000` … `frameCount - 1`).
  final int frameCount;

  /// Asset folder containing the sprite sequence.
  final String assetFolder;

  /// Filename prefix before the zero-padded index.
  final String assetPrefix;

  /// Flutter asset package (defaults to [AppAssets.package]).
  final String? package;

  /// How the current frame is inscribed within [size].
  final BoxFit fit;

  /// Builds sprite asset paths for the given configuration.
  @visibleForTesting
  static List<String> generateFramePaths({
    required int frameCount,
    String assetFolder = 'assets/lottie',
    String assetPrefix = 'sprite_',
  }) {
    assert(frameCount > 0, 'frameCount must be greater than 0');

    return List.generate(
      frameCount,
      (index) =>
          '$assetFolder/$assetPrefix${index.toString().padLeft(3, '0')}.png',
    );
  }

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<String> _frames;

  @override
  void initState() {
    super.initState();
    _frames = _buildFrames();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.frameCount != widget.frameCount ||
        oldWidget.assetFolder != widget.assetFolder ||
        oldWidget.assetPrefix != widget.assetPrefix) {
      _frames = _buildFrames();
    }

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  List<String> _buildFrames() {
    return AppLoadingIndicator.generateFramePaths(
      frameCount: widget.frameCount,
      assetFolder: widget.assetFolder,
      assetPrefix: widget.assetPrefix,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final index =
                (_controller.value * _frames.length).floor() % _frames.length;

            return Image.asset(
              _frames[index],
              package: widget.package,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              fit: widget.fit,
              width: widget.size,
              height: widget.size,
            );
          },
        ),
      ),
    );
  }
}
