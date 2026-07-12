import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
        assetPath: 'assets/images/branches/noresults.png',
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
