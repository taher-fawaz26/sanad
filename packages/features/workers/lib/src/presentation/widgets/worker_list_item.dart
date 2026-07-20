import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/widgets/worker_actions_bottom_sheet.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// Worker row — Figma team card (`1526:12324`).
class WorkerListItem extends StatelessWidget {
  const WorkerListItem({required this.worker, super.key, this.onTap});

  final WorkerEntity worker;

  /// Overrides default "open worker details" navigation — used by the
  /// search sheet to close itself before navigating.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppEntityListItem(
      title: worker.fullName,
      caption: worker.role,
      leading: AppAvatar(
        initials: worker.initials,
        backgroundColor: colors.primary,
        showStatusDot: worker.status == WorkerStatus.active,
      ),
      badge: _statusBadge(worker.status),
      trailing: Semantics(
        label: 'workers.more_actions'.tr(),
        child: AppIconButton(
          icon: Icons.more_vert,
          iconColor: colors.textPrimary,
          onTap: () => showWorkerActionsBottomSheet(
            context: context,
            worker: worker,
          ),
        ),
      ),
      onTap:
          onTap ??
          () => context.push(
            WorkerRoutes.detailsFor(worker.id),
            extra: worker,
          ),
    );
  }

  AppStatusBadge _statusBadge(WorkerStatus status) => switch (status) {
    WorkerStatus.active => AppStatusBadge(
      label: 'workers.status_active'.tr(),
      type: AppStatusBadgeType.success,
      size: AppStatusBadgeSize.dense,
      outlined: true,
    ),
    WorkerStatus.inactive => AppStatusBadge(
      label: 'workers.status_suspended'.tr(),
      type: AppStatusBadgeType.alert,
      size: AppStatusBadgeSize.dense,
    ),
  };
}
