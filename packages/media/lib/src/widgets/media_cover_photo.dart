import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:media/src/widgets/media_busy_overlay.dart';
import 'package:media/src/widgets/media_edit_button.dart';
import 'package:media/src/widgets/media_failure_overlay.dart';
import 'package:media/src/widgets/media_skeletons.dart';

/// A rectangular cover-photo slot — pure and prop-driven (no bloc, no upload
/// knowledge). The consuming feature maps its own state onto these props.
///
/// While [isBusy], the edit affordance is hidden so it can't be tapped mid-
/// upload — [onCancel] (if supplied) is the only interaction. After a
/// failure, the edit affordance returns (picking a new image is always
/// allowed) alongside an optional [onRetry].
class MediaCoverPhoto extends StatelessWidget {
  const MediaCoverPhoto({
    required this.onEditTap,
    this.imageUrl,
    this.isBusy = false,
    this.isLoading = false,
    this.hasFailed = false,
    this.progress = 0.0,
    this.errorMessage,
    this.heroTag,
    this.height = 120,
    this.borderRadius,
    this.onCancel,
    this.onRetry,
    super.key,
  });

  final String? imageUrl;
  final bool isBusy;
  final bool isLoading;
  final bool hasFailed;
  final double progress;
  final String? errorMessage;
  final Object? heroTag;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback onEditTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

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
          MediaBusyOverlay(
            progress: progress,
            borderRadius: radius,
            onCancel: onCancel,
          )
        else if (hasFailed)
          MediaFailureOverlay(
            errorMessage: errorMessage,
            onRetry: onRetry,
            borderRadius: radius,
          ),
        if (!isBusy)
          Positioned(
            top: 8,
            right: 8,
            child: MediaEditButton(onTap: onEditTap),
          ),
      ],
    );
  }
}
