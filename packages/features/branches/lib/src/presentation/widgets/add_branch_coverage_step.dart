import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Add branch — Step 2 coverage.
///
/// Empty: Figma `347:13772`.
/// Filled: Figma `1514:7822` — a "Coverage area" section with green area
/// chips. Editing happens through the map picker only.
class AddBranchCoverageStep extends StatelessWidget {
  const AddBranchCoverageStep({
    required this.onEditCoverage,
    this.pickedAddress,
    this.servingAreas = const [],
    this.radiusKm,
    super.key,
  });

  /// Opens the coverage area map picker to add or edit coverage.
  final VoidCallback onEditCoverage;
  final String? pickedAddress;
  final List<ServingArea> servingAreas;
  final double? radiusKm;

  bool get _hasCoverage =>
      radiusKm != null && pickedAddress != null && pickedAddress!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasCoverage) {
      return _CoverageAreasContent(
        servingAreas: servingAreas,
        onEditCoverage: onEditCoverage,
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

/// Selected coverage rendered as a "Coverage area" section with green area
/// chips (Figma `1514:7822`). Tapping re-opens the map picker to edit.
class _CoverageAreasContent extends StatelessWidget {
  const _CoverageAreasContent({
    required this.servingAreas,
    required this.onEditCoverage,
  });

  final List<ServingArea> servingAreas;
  final VoidCallback onEditCoverage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: GestureDetector(
        onTap: onEditCoverage,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSection(
              title: 'branches.details.section_coverage'.tr(),
              size: AppSectionSize.compact,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: servingAreas.isEmpty
                  ? Text(
                      'branches.details.no_serving_areas'.tr(),
                      style: context.appTypography.smallNormal.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final area in servingAreas)
                          AppChip(
                            label: area.name,
                            tone: AppChipTone.softSuccess,
                            icon: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colors.palettes.main.shade700,
                            ),
                            iconPosition: AppChipIconPosition.left,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
