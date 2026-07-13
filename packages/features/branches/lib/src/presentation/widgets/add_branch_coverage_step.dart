import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Figma Add branch — Step 2 coverage empty state (`347:13772`).
class AddBranchCoverageStep extends StatelessWidget {
  const AddBranchCoverageStep({
    required this.onAddLocation,
    this.pickedAddress,
    super.key,
  });

  final VoidCallback onAddLocation;
  final String? pickedAddress;

  @override
  Widget build(BuildContext context) {
    if (pickedAddress != null && pickedAddress!.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: AppMapLinkCard(
          title: 'branches.location_picker.specified_location'.tr(),
          caption: pickedAddress!,
          leading: AppSvgPicture.asset(
            AppSvgs.map,
            width: AppDimension.iconLg,
            height: AppDimension.iconLg,
          ),
          onTap: onAddLocation,
        ),
      );
    }

    return Center(
      child: AppEmptyState(
        illustration: AppEmptyStateImage(
          assetPath: AppImages.noBranchLocations,
          width: responsiveDimension(218),
          height: responsiveDimension(126),
        ),
        title: 'branches.add_branch.coverage_title'.tr(),
        description: 'branches.add_branch.coverage_description'.tr(),
      ),
    );
  }
}
