import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Add branch — Step 2 "Location access needed" state.
///
/// Shown when device location permission is permanently denied (or location
/// services are off) and the user tries to configure branch coverage.
///
/// Figma `location-permission-denied` (`1517:9804`).
class AddBranchLocationPermissionBody extends StatelessWidget {
  const AddBranchLocationPermissionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsiveDimension(80),
              height: responsiveDimension(80),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_outlined,
                size: responsiveDimension(40),
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            Text(
              'branches.add_branch.location_access_title'.tr(),
              textAlign: TextAlign.center,
              style: typography.title3.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'branches.add_branch.location_access_description'.tr(),
              textAlign: TextAlign.center,
              style: typography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
