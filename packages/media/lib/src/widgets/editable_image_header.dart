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
    this.coverBusy = false,
    this.avatarBusy = false,
    this.coverProgress = 0.0,
    this.avatarProgress = 0.0,
    this.coverLoading = false,
    this.avatarLoading = false,
    this.coverHeroTag,
    this.avatarHeroTag,
    super.key,
  });

  final String? coverUrl;
  final String? avatarUrl;
  final String? title;
  final String? subtitle;
  final bool coverBusy;
  final bool avatarBusy;
  final double coverProgress;
  final double avatarProgress;
  final bool coverLoading;
  final bool avatarLoading;
  final Object? coverHeroTag;
  final Object? avatarHeroTag;
  final VoidCallback onEditCover;
  final VoidCallback onEditAvatar;

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
          progress: coverProgress,
          heroTag: coverHeroTag,
          onEditTap: onEditCover,
        ),
        Row(
          spacing: AppSpacing.lg,
          children: [
            MediaAvatar(
              imageUrl: avatarUrl,
              isBusy: avatarBusy,
              isLoading: avatarLoading,
              progress: avatarProgress,
              heroTag: avatarHeroTag,
              onEditTap: onEditAvatar,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: typography.title3.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
