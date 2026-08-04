import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:media/src/config/media_viewer_config.dart';

/// Full-screen image viewer: pinch-to-zoom, double-tap zoom, pan, inertia,
/// and optional swipe-to-dismiss + Hero transition. Backed entirely by
/// `extended_image`'s gesture mode — no custom viewer logic.
class MediaViewerPage extends StatelessWidget {
  const MediaViewerPage({
    required this.imageUrl,
    this.config = const MediaViewerConfig(),
    super.key,
  });

  final String imageUrl;
  final MediaViewerConfig config;

  static Route<void> route({
    required String imageUrl,
    MediaViewerConfig config = const MediaViewerConfig(),
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => MediaViewerPage(imageUrl: imageUrl, config: config),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: config.backgroundColor,
      appBar: AppBar(
        backgroundColor: config.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SizedBox.expand(
        child: ExtendedImage.network(
          imageUrl,
          mode: ExtendedImageMode.gesture,
          enableSlideOutPage: config.enableSlideOut,
          heroBuilderForSlidingPage: config.heroTag == null
              ? null
              : (widget) => Hero(tag: config.heroTag!, child: widget),
          initGestureConfigHandler: (_) => GestureConfig(
            minScale: config.minScale,
            maxScale: config.maxScale,
            animationMinScale: config.minScale * 0.8,
            animationMaxScale: config.maxScale * 1.1,
          ),
        ),
      ),
    );
  }
}
