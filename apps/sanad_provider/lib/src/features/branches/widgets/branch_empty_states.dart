import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/assets/provider_images.dart';

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
        assetPath: ProviderImages.noResults,
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

/// Figma `empty states / Branch with no team` (`321:8319`).
class BranchWorkersEmptyState extends StatelessWidget {
  const BranchWorkersEmptyState({
    super.key,
    this.onAssignWorker,
  });

  final VoidCallback? onAssignWorker;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustration: AppEmptyStateImage(
        assetPath: ProviderImages.worker,
        width: responsiveDimension(EmptyStateTokens.workerIllustrationWidth),
        height: responsiveDimension(EmptyStateTokens.workerIllustrationHeight),
      ),
      title: 'branches.empty_workers_title'.tr(),
      description: 'branches.empty_workers_description'.tr(),
      actionLabel: 'branches.empty_workers_action'.tr(),
      onAction: onAssignWorker,
    );
  }
}
