import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';

/// Bordered worker row — Figma add-branch workers list (`972:9117`).
///
/// Layout: `[Avatar] [Name + Role] …… [optional trailing]`
class WorkerListCard extends StatelessWidget {
  const WorkerListCard({
    required this.worker,
    super.key,
    this.onTap,
    this.onRemove,
  });

  final WorkerEntity worker;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AppListCard(
      title: worker.fullName,
      caption: worker.role,
      captionStyle: typography.smallNormal.copyWith(color: colors.primary),
      leading: AppAvatar(
        initials: worker.initials,
        backgroundColor: colors.primary,
        showStatusDot: true,
      ),
      trailing: onRemove == null
          ? null
          : AppIconButton(
              iconAsset: AppSvgs.trash,
              size: AppIconButtonSize.small,
              semanticLabel: 'workers.remove_worker'.tr(),
              onTap: onRemove,
            ),
      onTap: onTap,
    );
  }
}
