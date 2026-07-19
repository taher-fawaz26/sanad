import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Figma `branches-empty-state` search-results variant (`1514:7861`).
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
        assetPath: AppImages.emptyState,
        width: responsiveDimension(EmptyStateTokens.searchIllustrationWidth),
        height: responsiveDimension(EmptyStateTokens.searchIllustrationHeight),
      ),
      title: 'branches.empty_search_title'.tr(),
      description: 'branches.empty_search_description'.tr(
        namedArgs: {'query': query},
      ),
      actionLabel: 'branches.empty_search_action'.tr(),
      actionStyle: AppEmptyStateActionStyle.link,
      onAction: onClearSearch,
    );
  }
}
