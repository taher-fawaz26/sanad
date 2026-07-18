import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Figma branches list empty (`1517:9365`) — no branches yet.
class BranchesFirstEmptyState extends StatelessWidget {
  const BranchesFirstEmptyState({
    super.key,
    this.onAddBranch,
  });

  final VoidCallback? onAddBranch;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const circleSize = 120.0;
    const iconSize = 64.0;
    const buttonWidth = 130.0;
    const buttonHeight = 32.0;
    final spec = EmptyStateTokens.resolve(
      colors: colors,
      typography: context.appTypography,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spec.horizontalPadding,
        spec.topPadding,
        spec.horizontalPadding,
        spec.bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: responsiveDimension(circleSize),
            height: responsiveDimension(circleSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.palettes.sky.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvgPicture.asset(
                  AppSvgs.branchStore,
                  width: responsiveDimension(iconSize),
                  height: responsiveDimension(iconSize),
                  colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          SizedBox(height: spec.sectionGap),
          SizedBox(
            width: spec.contentWidth,
            child: Column(
              children: [
                Text(
                  'branches.empty_zero_title'.tr(),
                  style: spec.titleStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spec.textGap),
                Text(
                  'branches.empty_zero_description'.tr(),
                  style: spec.descriptionStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (onAddBranch != null) ...[
            SizedBox(height: spec.sectionGap),
            SizedBox(
              width: responsiveDimension(buttonWidth),
              height: responsiveDimension(buttonHeight),
              child: AppButtonPresets.outline(
                label: 'branches.empty_zero_action'.tr(),
                size: AppButtonSize.small,
                onPressed: onAddBranch,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Filter applied but no branches match.
class BranchesFilterEmptyState extends StatelessWidget {
  const BranchesFilterEmptyState({
    super.key,
    this.onClearFilter,
  });

  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    return AppGenericEmptyState(
      title: 'branches.empty_filter_title'.tr(),
      description: 'branches.empty_filter_description'.tr(),
      actionLabel: 'branches.empty_filter_action'.tr(),
      onAction: onClearFilter,
    );
  }
}

/// Figma `empty states / No search results` (`322:9661`).
class BranchesSearchEmptyState extends StatelessWidget {
  const BranchesSearchEmptyState({
    required this.query,
    super.key,
    this.onClearSearch,
  });

  final String query;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustration: AppEmptyStateImage(
        assetPath: AppImages.noBranchResults,
        width: responsiveDimension(EmptyStateTokens.searchIllustrationWidth),
        height: responsiveDimension(EmptyStateTokens.searchIllustrationHeight),
      ),
      title: 'branches.empty_search_title'.tr(),
      description: 'branches.empty_search_description'.tr(
        namedArgs: {'query': query},
      ),
      actionLabel: 'branches.empty_search_action'.tr(),
      onAction: onClearSearch,
    );
  }
}
