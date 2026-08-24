import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One Quick Actions row — Figma `6755:26006`.
///
/// [iconAsset] is an SVG asset path (from `AppSvgs`) rendered in the primary
/// green tint inside a rounded holder, matching the Figma design assets.
class HomeQuickActionTile extends StatelessWidget {
  const HomeQuickActionTile({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    super.key,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(responsiveSpacing(14)),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Container(
                width: responsiveDimension(32),
                height: responsiveDimension(32),
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppSvgPicture.asset(
                  iconAsset,
                  width: responsiveDimension(18),
                  height: responsiveDimension(18),
                  colorFilter: ColorFilter.mode(
                    colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: typography.smallNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Transform.flip(
                key: const ValueKey('home_quick_action_tile_chevron_flip'),
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
