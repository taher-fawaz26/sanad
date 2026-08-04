import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:media/src/widgets/media_busy_overlay.dart';
import 'package:media/src/widgets/media_edit_button.dart';
import 'package:media/src/widgets/media_skeletons.dart';

/// A rectangular cover-photo slot — pure and prop-driven (no bloc, no upload
/// knowledge). The consuming feature maps its own state onto these props.
class MediaCoverPhoto extends StatelessWidget {
  const MediaCoverPhoto({
    required this.onEditTap,
    this.imageUrl,
    this.isBusy = false,
    this.isLoading = false,
    this.progress = 0.0,
    this.heroTag,
    this.height = 120,
    this.borderRadius,
    super.key,
  });

  final String? imageUrl;
  final bool isBusy;
  final bool isLoading;
  final double progress;
  final Object? heroTag;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? BorderRadius.circular(12);

    if (isLoading) {
      return MediaCoverSkeleton(height: height, borderRadius: radius);
    }

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    Widget? image = hasImage
        ? AppNetworkImage(
            imageUrl!,
            height: height,
            width: double.infinity,
            borderRadius: radius,
          )
        : null;
    if (image != null && heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: radius,
          ),
          child: image ?? const SizedBox.shrink(),
        ),
        if (isBusy)
          MediaBusyOverlay(progress: progress, borderRadius: radius),
        Positioned(
          top: 8,
          right: 8,
          child: MediaEditButton(onTap: onEditTap),
        ),
      ],
    );
  }
}
