import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:media/src/widgets/media_avatar.dart';
import 'package:media/src/widgets/media_cover_photo.dart';

/// A generic Facebook-style identity header: cover photo + circular avatar +
/// title + subtitle, both images independently editable.
///
/// Pure and prop-driven — the consuming feature owns state (current URLs,
/// busy/progress) and maps it onto these props. Reusable for organization,
/// user, worker, branch, and other identity surfaces.
class EditableImageHeader extends StatelessWidget {
  const EditableImageHeader({
    required this.onEditCover,
    required this.onEditAvatar,
    this.coverUrl,
    this.avatarUrl,
    this.title,
    this.subtitle,
    this.badge,
    this.coverBusy = false,
    this.avatarBusy = false,
    this.coverFailed = false,
    this.avatarFailed = false,
    this.coverProgress = 0.0,
    this.avatarProgress = 0.0,
    this.coverLoading = false,
    this.avatarLoading = false,
    this.coverErrorMessage,
    this.avatarErrorMessage,
    this.coverHeroTag,
    this.avatarHeroTag,
    this.onCancelCover,
    this.onCancelAvatar,
    this.onRetryCover,
    this.onRetryAvatar,
    super.key,
  });

  final String? coverUrl;
  final String? avatarUrl;
  final String? title;
  final String? subtitle;

  /// Optional status pill shown to the right of [title] (e.g. a review/
  /// completion status badge).
  final Widget? badge;
  final bool coverBusy;
  final bool avatarBusy;

  /// Whether the last upload for this slot failed — shows the failure
  /// overlay and (if the matching `onRetry*` callback is supplied) a retry
  /// affordance instead of the busy overlay.
  final bool coverFailed;
  final bool avatarFailed;
  final double coverProgress;
  final double avatarProgress;
  final bool coverLoading;
  final bool avatarLoading;
  final String? coverErrorMessage;
  final String? avatarErrorMessage;
  final Object? coverHeroTag;
  final Object? avatarHeroTag;
  final VoidCallback onEditCover;
  final VoidCallback onEditAvatar;

  /// Cancels an in-flight upload for the matching slot. `null` hides the
  /// cancel affordance on the busy overlay.
  final VoidCallback? onCancelCover;
  final VoidCallback? onCancelAvatar;

  /// Retries the last failed upload for the matching slot. `null` hides the
  /// retry affordance on the failure overlay.
  final VoidCallback? onRetryCover;
  final VoidCallback? onRetryAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.lg,
      children: [
        MediaCoverPhoto(
          imageUrl: coverUrl,
          isBusy: coverBusy,
          isLoading: coverLoading,
          hasFailed: coverFailed,
          progress: coverProgress,
          errorMessage: coverErrorMessage,
          heroTag: coverHeroTag,
          onEditTap: onEditCover,
          onCancel: onCancelCover,
          onRetry: onRetryCover,
        ),
        Row(
          spacing: AppSpacing.lg,
          children: [
            MediaAvatar(
              imageUrl: avatarUrl,
              isBusy: avatarBusy,
              isLoading: avatarLoading,
              hasFailed: avatarFailed,
              progress: avatarProgress,
              errorMessage: avatarErrorMessage,
              heroTag: avatarHeroTag,
              onEditTap: onEditAvatar,
              onCancel: onCancelAvatar,
              onRetry: onRetryAvatar,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  if (title != null || badge != null)
                    Row(
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              style: typography.title3.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (badge != null) badge!,
                      ],
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: typography.smallNormal.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
