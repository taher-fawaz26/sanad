import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

/// Declarative configuration for the fullscreen viewer.
class MediaViewerConfig extends Equatable {
  const MediaViewerConfig({
    this.heroTag,
    this.backgroundColor = const Color(0xFF000000),
    this.enableSlideOut = true,
    this.minScale = 1.0,
    this.maxScale = 5.0,
  });

  /// Shared Hero tag connecting the thumbnail to the fullscreen image.
  final Object? heroTag;

  final Color backgroundColor;

  /// Enable swipe-down-to-dismiss.
  final bool enableSlideOut;

  final double minScale;
  final double maxScale;

  @override
  List<Object?> get props => [
    heroTag,
    backgroundColor,
    enableSlideOut,
    minScale,
    maxScale,
  ];
}
