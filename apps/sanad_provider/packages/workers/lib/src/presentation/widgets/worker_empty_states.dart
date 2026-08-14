import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Search scope for empty-state copy.
enum WorkerSearchScope {
  team,
  invitations,
}

/// Figma workers search empty (`1526:12837`) — users icon + Cancel link.
class WorkersSearchEmptyState extends StatelessWidget {
  const WorkersSearchEmptyState({
    required this.scope,
    super.key,
    this.onCancel,
  });

  final WorkerSearchScope scope;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final iconSize = responsiveDimension(48);
    final title = switch (scope) {
      WorkerSearchScope.team => 'workers.search_empty_title'.tr(),
      WorkerSearchScope.invitations =>
        'workers.invitations_search_empty_title'.tr(),
    };
    final description = switch (scope) {
      WorkerSearchScope.team => 'workers.search_empty_description'.tr(),
      WorkerSearchScope.invitations =>
        'workers.invitations_search_empty_description'.tr(),
    };

    return AppEmptyState(
      illustration: AppSvgPicture.asset(
        AppSvgs.users2,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          context.appColors.textMuted,
          BlendMode.srcIn,
        ),
      ),
      title: title,
      description: description,
      actionLabel: 'common.cancel'.tr(),
      actionStyle: AppEmptyStateActionStyle.link,
      onAction: onCancel,
    );
  }
}
