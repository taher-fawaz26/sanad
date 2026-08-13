import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/widgets/worker_action_invokers.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// Swipe-group tag shared by every [WorkerListItem] so only one row's swipe
/// actions stay open at a time — wrap the list in `AppSwipeActionsGroup`.
const workerSwipeGroupTag = 'workers';

/// Worker row — Figma team card (`1526:12324`).
///
/// Contextual actions (Edit / Suspend-Unsuspend / Delete) are exposed only
/// via swipe-to-reveal (`AppSwipeActions`) — there is no secondary "more"
/// menu. All actions call the exact same `WorkerActionCubit` methods via
/// `worker_action_invokers.dart`.
class WorkerListItem extends StatelessWidget {
  const WorkerListItem({required this.worker, super.key, this.onTap});

  final WorkerEntity worker;

  /// Overrides default "open worker details" navigation — used by the
  /// search sheet to close itself before navigating.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuspended = worker.status == WorkerStatus.inactive;

    return AppSwipeActions(
      groupTag: workerSwipeGroupTag,
      actions: [
        AppSwipeAction(
          svgAsset: AppSvgs.branchEdit,
          semanticLabel: 'workers.action_edit'.tr(),
          onPressed: () => _editWorker(context),
        ),
        AppSwipeAction(
          svgAsset: AppSvgs.workerSuspend,
          semanticLabel: isSuspended
              ? 'workers.action_unsuspend'.tr()
              : 'workers.action_suspend'.tr(),
          variant: AppSwipeActionVariant.warning,
          onPressed: () => confirmAndChangeWorkerStatus(
            context: context,
            worker: worker,
            isSuspending: !isSuspended,
          ),
        ),
        AppSwipeAction(
          svgAsset: AppSvgs.trashBold,
          semanticLabel: 'workers.action_delete'.tr(),
          variant: AppSwipeActionVariant.destructive,
          onPressed: () =>
              confirmAndDeleteWorker(context: context, worker: worker),
        ),
      ],
      child: AppEntityListItem(
        title: worker.fullName,
        caption: worker.role,
        leading: AppAvatar(
          image:
              worker.profilePicUrl != null && worker.profilePicUrl!.isNotEmpty
              ? NetworkImage(worker.profilePicUrl!)
              : null,
          initials: worker.initials,
          backgroundColor: colors.primary,
          showStatusDot: worker.status == WorkerStatus.active,
        ),
        badge: _statusBadge(worker.status),
        onTap: onTap ?? () => _openDetails(context),
      ),
    );
  }

  Future<void> _editWorker(BuildContext context) async {
    final bloc = context.read<WorkersListBloc>();
    final updated = await context.push<WorkerEntity>(
      WorkerRoutes.editWorkerFor(worker.id),
      extra: worker,
    );
    if (updated != null) bloc.add(WorkerReplacedInListEvent(updated));
  }

  Future<void> _openDetails(BuildContext context) async {
    final bloc = context.read<WorkersListBloc>();
    final updated = await context.push<WorkerEntity>(
      WorkerRoutes.detailsFor(worker.id),
      extra: worker,
    );
    if (updated != null) bloc.add(WorkerReplacedInListEvent(updated));
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
