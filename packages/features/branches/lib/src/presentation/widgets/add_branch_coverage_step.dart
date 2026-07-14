import 'package:app_assets/app_assets.dart';
import 'package:maps/maps.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Add branch — Step 2 coverage.
///
/// Empty: Figma `347:13772`.
/// Filled: Figma `972:9206`.
class AddBranchCoverageStep extends StatelessWidget {
  const AddBranchCoverageStep({
    required this.onEditCoverage,
    this.pickedAddress,
    this.coveredAreas = const [],
    this.radiusKm,
    super.key,
  });

  /// Opens the coverage area screen to add or edit coverage.
  final VoidCallback onEditCoverage;
  final String? pickedAddress;
  final List<String> coveredAreas;
  final double? radiusKm;

  bool get _hasCoverage =>
      radiusKm != null &&
      pickedAddress != null &&
      pickedAddress!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasCoverage) {
      return _CoverageSetContent(
        address: pickedAddress!,
        coveredAreas: coveredAreas,
        radiusKm: radiusKm!,
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

/// Figma success visual after coverage is confirmed (`972:9206`).
class _CoverageSetContent extends StatelessWidget {
  const _CoverageSetContent({
    required this.address,
    required this.coveredAreas,
    required this.radiusKm,
    required this.onEditCoverage,
  });

  final String address;
  final List<String> coveredAreas;
  final double radiusKm;
  final VoidCallback onEditCoverage;

  String get _areaLabel {
    if (coveredAreas.isNotEmpty) return coveredAreas.first;
    final firstPart = address.split(',').first.trim();
    return firstPart.isNotEmpty ? firstPart : address;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onEditCoverage,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: responsiveDimension(80),
                  height: responsiveDimension(80),
                  decoration: BoxDecoration(
                    color: colors.success100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppSvgPicture.asset(
                    AppSvgs.mapPinMarker,
                    width: responsiveDimension(36),
                    height: responsiveDimension(48),
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),
                Text(
                  'branches.add_branch.coverage_set_title'.tr(),
                  textAlign: TextAlign.center,
                  style: typography.title3.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'branches.add_branch.coverage_set_description'.tr(
                    namedArgs: {
                      'area': _areaLabel,
                      'radius': formatRadiusKm(radiusKm),
                      'count': '${coveredAreas.length}',
                    },
                  ),
                  textAlign: TextAlign.center,
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (coveredAreas.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xxxl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final area in coveredAreas)
                  AppChip(
                    label: area,
                    tone: AppChipTone.softNeutral,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
