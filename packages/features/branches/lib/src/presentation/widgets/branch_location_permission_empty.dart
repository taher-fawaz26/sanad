import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Figma location permission denied in add-branch wizard (`1517:9804`).
class BranchLocationPermissionEmpty extends StatelessWidget {
  const BranchLocationPermissionEmpty({
    required this.onOpenSettings,
    super.key,
    this.onRetry,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const badgeSize = 80.0;
    const iconSize = 36.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: responsiveDimension(badgeSize),
              height: responsiveDimension(badgeSize),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.palettes.sky.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvgPicture.asset(
                    AppSvgs.mapPinOutline,
                    width: responsiveDimension(iconSize),
                    height: responsiveDimension(iconSize),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'branches.add_branch.location_permission_title'.tr(),
              style: context.appTypography.title3.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'branches.add_branch.location_permission_description'.tr(),
              style: context.appTypography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'branches.location_picker.open_settings'.tr(),
              onPressed: onOpenSettings,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.sm),
              AppButtonPresets.outline(
                label: 'branches.add_branch.location_permission_retry'.tr(),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
