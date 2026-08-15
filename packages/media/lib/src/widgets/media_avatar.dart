import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:media/src/widgets/media_busy_overlay.dart';
import 'package:media/src/widgets/media_edit_button.dart';
import 'package:media/src/widgets/media_failure_overlay.dart';
import 'package:media/src/widgets/media_skeletons.dart';

/// A circular avatar/logo slot — pure and prop-driven (no bloc, no upload
/// knowledge).
///
/// While [isBusy], the edit affordance is hidden so it can't be tapped mid-
/// upload — [onCancel] (if supplied) is the only interaction. After a
/// failure, the edit affordance returns (picking a new image is always
/// allowed) alongside an optional [onRetry].
class MediaAvatar extends StatelessWidget {
  const MediaAvatar({
    required this.onEditTap,
    this.imageUrl,
    this.isBusy = false,
    this.isLoading = false,
    this.hasFailed = false,
    this.progress = 0.0,
    this.errorMessage,
    this.heroTag,
    this.size = 76,
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
  final double size;
  final VoidCallback onEditTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (isLoading) return MediaAvatarSkeleton(size: size);

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    Widget? image = hasImage
        ? ClipOval(
            child: AppNetworkImage(imageUrl!, width: size, height: size),
          )
        : null;
    if (image != null && heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.09),
                  blurRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: image ?? const SizedBox.shrink(),
          ),
          // `Positioned.fill` (inside both overlays) must mount directly
          // under this `Stack` — wrapping it in an extra `ClipOval` here
          // would break Stack's parent-data requirement. Rounding is done
          // via each overlay's own `borderRadius` instead.
          if (isBusy)
            MediaBusyOverlay(
              progress: progress,
              borderRadius: BorderRadius.circular(size / 2),
              onCancel: onCancel,
            )
          else if (hasFailed)
            MediaFailureOverlay(
              errorMessage: errorMessage,
              onRetry: onRetry,
              borderRadius: BorderRadius.circular(size / 2),
            ),
          if (!isBusy)
            Positioned(
              right: 0,
              bottom: 0,
              child: MediaEditButton(onTap: onEditTap),
            ),
        ],
      ),
    );
  }
}
