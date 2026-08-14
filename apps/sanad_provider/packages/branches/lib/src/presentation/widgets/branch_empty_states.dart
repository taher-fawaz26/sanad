import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Figma `branches-empty-state` — no branches yet (`328:9898`).
class BranchesEmptyState extends StatelessWidget {
  const BranchesEmptyState({super.key, this.onAddBranch});

  final VoidCallback? onAddBranch;

  @override
  Widget build(BuildContext context) {
    final iconSize = responsiveDimension(48);

    return AppEmptyState(
      illustration: AppSvgPicture.asset(
        AppSvgs.pin,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          context.appColors.textMuted,
          BlendMode.srcIn,
        ),
      ),
      title: 'branches.empty_first_branch_title'.tr(),
      description: 'branches.empty_first_branch_description'.tr(),
      actionLabel: 'branches.empty_first_branch_action'.tr(),
      onAction: onAddBranch,
    );
  }
}

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
    final iconSize = responsiveDimension(48);

    return AppEmptyState(
      illustration: AppSvgPicture.asset(
        AppSvgs.searchAlert,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          context.appColors.textMuted,
          BlendMode.srcIn,
        ),
      ),
      title: 'branches.empty_search_title'.tr(),
      description: 'branches.empty_search_description'.tr(
        namedArgs: {'query': query},
      ),
      actionLabel: 'common.cancel'.tr(),
      actionStyle: AppEmptyStateActionStyle.link,
      onAction: onClearSearch,
    );
  }
}
