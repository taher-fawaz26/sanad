import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_nav_pill.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:sanad_client/src/ui/glass/client_glass_tokens.dart';

/// The Home shell's persistent top row — Figma `header-profile` (`7124:29682`):
/// profile avatar, the three-segment nav pill, and the History button.
///
/// Stateless and read-only: it forwards taps to callbacks and owns nothing —
/// the shell decides what a tap on the avatar or History means (both are
/// pushes, not shell branches, so they belong to the shell's navigation, not
/// to this row).
class AiHomeHeader extends StatelessWidget {
  /// Creates the header.
  const AiHomeHeader({
    required this.selected,
    required this.onSelected,
    required this.onProfileTap,
    required this.onHistoryTap,
    super.key,
  });

  /// The active nav-pill destination.
  final AiHomeDestination selected;

  /// Fired when a different pill segment is tapped.
  final ValueChanged<AiHomeDestination> onSelected;

  /// Fired when the profile avatar is tapped.
  final VoidCallback onProfileTap;

  /// Fired when the History button is tapped.
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) => Padding(
    // Figma `header-profile` (`7124:29682`): 20/8 padding, the three controls
    // spread with `space-between` — avatar hard against the leading edge,
    // History against the trailing one, pill between them.
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: 'ai_chat.profile'.tr(),
          child: InkWell(
            onTap: onProfileTap,
            customBorder: const CircleBorder(),
            child: const _ProfileAvatar(),
          ),
        ),
        // `Flexible`, not a fixed 211dp: Figma's frame is 390dp, where these
        // three controls and their gaps fit with room to spare. At 360dp they
        // are a hair over, so the pill gives that back — its label is already
        // capped and ellipsized — rather than overflowing the row.
        Flexible(
          child: AiHomeNavPill(selected: selected, onSelected: onSelected),
        ),
        // 55dp with a 24dp glyph — Figma `history-button` (`7124:29686`),
        // now glass to match the pill beside it. It was `background`
        // (`#F9F9FA`), the page's own colour, so the control had no visible
        // surface at all; a flat white fixed that and hid the wash instead.
        ClientGlassSurface(
          level: ClientGlassLevel.nav,
          borderRadius: BorderRadius.circular(55 / 2),
          child: AiCircleIconButton(
            svgAsset: AppSvgs.aiChatNavHistory,
            semanticLabel: 'ai_chat.nav_history'.tr(),
            size: 55,
            iconSize: 24,
            iconColor: context.appColors.textSecondary,
            onTap: onHistoryTap,
          ),
        ),
      ],
    ),
  );
}

/// A 55dp portrait in a white ring — Figma's `header-profile` treatment
/// (`7124:29693`), which `AppAvatar` has no size tier or border option for.
///
/// Shows the design's portrait rather than a person glyph: Figma draws a
/// photograph here, and `Icons.person_outline_rounded` read as an empty
/// account slot instead of the signed-in user.
///
/// The image is a **placeholder** standing in for the account's own avatar
/// (see `AppImages.aiChatProfileAvatarPlaceholder`) — the moment a profile
/// avatar URL is available, that becomes the image and this stays only as the
/// fallback. An `errorBuilder` keeps a decode failure from taking the header
/// down with it.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  static const _size = 55.0;

  /// Figma's `border-6` white ring, which is what lifts the portrait off the
  /// page behind it.
  ///
  /// Deliberately not glass, unlike the two controls beside it: the ring is
  /// three points of a circle around an opaque photograph, so a backdrop
  /// filter would cost a full blur pass to tint a hairline nobody can see
  /// through anyway.
  static const _ringWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.controlFill,
        border: Border.all(color: colors.surface, width: _ringWidth),
      ),
      child: ClipOval(
        child: Image.asset(
          AppImages.aiChatProfileAvatarPlaceholder,
          package: AppAssets.package,
          fit: BoxFit.cover,
          // The source art is 1024², far larger than this ever draws.
          cacheWidth: (_size * 3).round(),
          errorBuilder: (context, _, _) => Icon(
            Icons.person_outline_rounded,
            color: colors.textSecondary,
            size: _size * 0.55,
          ),
        ),
      ),
    );
  }
}
