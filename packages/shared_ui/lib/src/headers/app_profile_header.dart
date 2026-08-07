import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/effects/avatar_collapse_effect.dart';
import 'package:shared_ui/src/effects/fade_title_effect.dart';
import 'package:shared_ui/src/widgets/app_verified_pill.dart';

/// Collapsing profile header: cover image, avatar, verified badge, title,
/// subtitle, and trailing actions — generalizes the pattern used across
/// organization/worker/client profile screens.
///
/// Expanded: large centered avatar over the cover image with title/subtitle
/// below it. Collapsed: a compact pinned bar with a small leading avatar and
/// the title, matching [AppNavBar]'s height.
///
/// Pass [onEditCover]/[onEditAvatar] to show a small edit affordance over
/// each image (only while expanded) — for screens where the cover/avatar are
/// user-editable. [coverBusy]/[avatarBusy] show a progress overlay in place
/// of the edit affordance while an upload is in flight.
class AppProfileHeader extends StatelessWidget {
  const AppProfileHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.coverImageUrl,
    this.avatarImageUrl,
    this.avatarInitials,
    this.verified = false,
    this.actions,
    this.onBack,
    this.onEditCover,
    this.onEditAvatar,
    this.coverBusy = false,
    this.avatarBusy = false,
    this.coverProgress = 0.0,
    this.avatarProgress = 0.0,
    this.expandedHeight = 260,
  });

  final String title;
  final String? subtitle;
  final String? coverImageUrl;
  final String? avatarImageUrl;
  final String? avatarInitials;
  final bool verified;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final VoidCallback? onEditCover;
  final VoidCallback? onEditAvatar;
  final bool coverBusy;
  final bool avatarBusy;
  final double coverProgress;
  final double avatarProgress;
  final double expandedHeight;

  static const double _collapsedHeight = 56;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        expandedHeight: expandedHeight,
        collapsedHeight: _collapsedHeight,
        title: title,
        subtitle: subtitle,
        coverImageUrl: coverImageUrl,
        avatarImageUrl: avatarImageUrl,
        avatarInitials: avatarInitials,
        verified: verified,
        actions: actions,
        onBack: onBack,
        onEditCover: onEditCover,
        onEditAvatar: onEditAvatar,
        coverBusy: coverBusy,
        avatarBusy: avatarBusy,
        coverProgress: coverProgress,
        avatarProgress: avatarProgress,
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.title,
    required this.subtitle,
    required this.coverImageUrl,
    required this.avatarImageUrl,
    required this.avatarInitials,
    required this.verified,
    required this.actions,
    required this.onBack,
    required this.onEditCover,
    required this.onEditAvatar,
    required this.coverBusy,
    required this.avatarBusy,
    required this.coverProgress,
    required this.avatarProgress,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final String title;
  final String? subtitle;
  final String? coverImageUrl;
  final String? avatarImageUrl;
  final String? avatarInitials;
  final bool verified;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final VoidCallback? onEditCover;
  final VoidCallback? onEditAvatar;
  final bool coverBusy;
  final bool avatarBusy;
  final double coverProgress;
  final double avatarProgress;

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = expandedHeight - collapsedHeight;
    final t = range <= 0 ? 0.0 : (1 - shrinkOffset / range).clamp(0.0, 1.0);
    final colors = context.appColors;
    final typography = context.appTypography;

    return SizedBox(
      height: expandedHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: coverImageUrl != null
                ? AppNetworkImage(coverImageUrl!)
                : ColoredBox(color: colors.primary),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.onBackground.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          if (onEditCover != null || coverBusy)
            Positioned(
              right: AppSpacing.md,
              top: 0,
              child: Opacity(
                opacity: t,
                child: SafeArea(
                  bottom: false,
                  child: _EditBadge(
                    busy: coverBusy,
                    progress: coverProgress,
                    onTap: onEditCover,
                  ),
                ),
              ),
            ),
          // Collapsed compact bar — fades in as the header collapses.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: collapsedHeight,
            child: FadeTitleEffect(
              t: 1 - t,
              child: ColoredBox(
                color: colors.surface,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      SizedBox(width: AppSpacing.md),
                      _Avatar(
                        imageUrl: avatarImageUrl,
                        initials: avatarInitials,
                        size: _AppProfileHeaderSizes.collapsedAvatarSize,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.regularNormal.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                      SizedBox(width: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Expanded content — fades out as the header collapses.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: t,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarCollapseEffect(
                      t: t,
                      expandedSize: _AppProfileHeaderSizes.expandedAvatarSize,
                      collapsedSize: _AppProfileHeaderSizes.collapsedAvatarSize,
                      collapsedAlignment: Alignment.center,
                      child: _Avatar(
                        imageUrl: avatarImageUrl,
                        initials: avatarInitials,
                        size: _AppProfileHeaderSizes.expandedAvatarSize,
                        border: Border.all(color: colors.surface, width: 3),
                        onEdit: onEditAvatar,
                        busy: avatarBusy,
                        progress: avatarProgress,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: typography.regularNone.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: typography.smallNormal.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ],
                    if (verified) ...[
                      SizedBox(height: AppSpacing.sm),
                      const AppVerifiedPill(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              left: AppSpacing.sm,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: IconButton(
                  icon: Icon(Icons.chevron_left, color: colors.onPrimary),
                  onPressed: onBack,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.coverImageUrl != coverImageUrl ||
        oldDelegate.avatarImageUrl != avatarImageUrl ||
        oldDelegate.avatarInitials != avatarInitials ||
        oldDelegate.verified != verified ||
        oldDelegate.coverBusy != coverBusy ||
        oldDelegate.avatarBusy != avatarBusy ||
        oldDelegate.coverProgress != coverProgress ||
        oldDelegate.avatarProgress != avatarProgress;
  }
}

/// Shared avatar sizing constants for the expanded/collapsed states.
abstract final class _AppProfileHeaderSizes {
  static const double expandedAvatarSize = 88;
  static const double collapsedAvatarSize = 32;
}

/// Small circular edit-pencil badge, or a progress spinner while [busy].
class _EditBadge extends StatelessWidget {
  const _EditBadge({required this.busy, required this.progress, this.onTap});

  final bool busy;
  final double progress;
  final VoidCallback? onTap;

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.onBackground.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: _size,
          height: _size,
          child: busy
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                    value: progress > 0 ? progress : null,
                  ),
                )
              : Icon(Icons.edit, size: 14, color: colors.onPrimary),
        ),
      ),
    );
  }
}

/// Continuously-sized circular avatar for the header's collapse animation.
///
/// [AppAvatar] only exposes fixed 24/40 dp tokens, which don't fit a header
/// that scales an avatar from 88 dp down to 32 dp — this renders the same
/// image/initials-fallback treatment at an arbitrary [size] instead.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    this.imageUrl,
    this.initials,
    this.border,
    this.onEdit,
    this.busy = false,
    this.progress = 0.0,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final BoxBorder? border;
  final VoidCallback? onEdit;
  final bool busy;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? AppNetworkImage(imageUrl!, width: size, height: size)
            : ColoredBox(
                color: colors.disabled,
                child: initials != null && initials!.isNotEmpty
                    ? Center(
                        child: Text(
                          initials!,
                          style: context.appTypography.regularNormal.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
      ),
    );

    final bordered = border == null
        ? avatar
        : DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, border: border),
            child: Padding(padding: const EdgeInsets.all(2), child: avatar),
          );

    if (onEdit == null && !busy) {
      return bordered;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bordered,
          Positioned(
            right: -4,
            bottom: -4,
            child: _EditBadge(busy: busy, progress: progress, onTap: onEdit),
          ),
        ],
      ),
    );
  }
}
