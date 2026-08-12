import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/widgets/action_confirmation_sheet.dart';
import 'package:workers/src/routes/worker_routes.dart';

const ({AppButtonType type, bool destructive}) _suspendButton = (
  type: AppButtonType.warning,
  destructive: false,
);
const ({AppButtonType type, bool destructive}) _unsuspendButton = (
  type: AppButtonType.primary,
  destructive: false,
);
const ({AppButtonType type, bool destructive}) _deleteButton = (
  type: AppButtonType.primary,
  destructive: true,
);

/// Figma `Views / Bottom Sheets` worker actions (`1526:12517`).
Future<void> showWorkerActionsBottomSheet({
  required BuildContext context,
  required WorkerEntity worker,
}) {
  final listBloc = context.read<WorkersListBloc>();
  final actionCubit = context.read<WorkerActionCubit>();
  final pageContext = context;

  return SheetNavigator.push<void>(
    context,
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: listBloc),
        BlocProvider.value(value: actionCubit),
      ],
      child: _WorkerActionsSheetBody(worker: worker, pageContext: pageContext),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.content,
      padChild: false,
    ),
  );
}

class _WorkerActionsSheetBody extends StatelessWidget {
  const _WorkerActionsSheetBody({
    required this.worker,
    required this.pageContext,
  });

  final WorkerEntity worker;
  final BuildContext pageContext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuspended = worker.status == WorkerStatus.inactive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View Details
        AppTableRow(
          title: 'workers.action_view_details'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: AppSvgPicture.asset(
            AppSvgs.branchView,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
          onTap: () async {
            final bloc = pageContext.read<WorkersListBloc>();
            Navigator.of(context).pop();
            final updated = await pageContext.push<WorkerEntity>(
              WorkerRoutes.detailsFor(worker.id),
              extra: worker,
            );
            if (updated != null) {
              bloc.add(WorkerReplacedInListEvent(updated));
            }
          },
        ),
        // Edit Information
        AppTableRow(
          title: 'workers.action_edit'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: AppSvgPicture.asset(
            AppSvgs.branchEdit,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
          onTap: () async {
            final bloc = pageContext.read<WorkersListBloc>();
            Navigator.of(context).pop();
            final updated = await pageContext.push<WorkerEntity>(
              WorkerRoutes.editWorkerFor(worker.id),
              extra: worker,
            );
            if (updated != null) {
              bloc.add(WorkerReplacedInListEvent(updated));
            }
          },
        ),
        const AppDivider(),
        // Suspend / Unsuspend Worker
        SheetActionRow(
          label: isSuspended
              ? 'workers.action_unsuspend'.tr()
              : 'workers.action_suspend'.tr(),
          svgAsset: AppSvgs.workerSuspend,
          color: colors.warning,
          onTap: () async {
            Navigator.of(context).pop();
            if (!pageContext.mounted) return;
            await _showStatusConfirmation(
              context: pageContext,
              worker: worker,
              isSuspending: !isSuspended,
            );
          },
        ),
        // Delete Worker
        SheetActionRow(
          label: 'workers.action_delete'.tr(),
          svgAsset: AppSvgs.trashBold,
          color: colors.error,
          onTap: () async {
            Navigator.of(context).pop();
            if (!pageContext.mounted) return;
            await _showDeleteConfirmation(
              context: pageContext,
              worker: worker,
            );
          },
        ),
      ],
    );
  }

  Future<void> _showStatusConfirmation({
    required BuildContext context,
    required WorkerEntity worker,
    required bool isSuspending,
  }) async {
    final btnConfig = isSuspending ? _suspendButton : _unsuspendButton;
    final confirmed = await showWorkerConfirmationSheet(
      context: context,
      title: isSuspending
          ? 'workers.suspend_title'.tr()
          : 'workers.unsuspend_title'.tr(),
      description: isSuspending
          ? 'workers.suspend_description'.tr(
              namedArgs: {'name': worker.fullName},
            )
          : 'workers.unsuspend_description'.tr(
              namedArgs: {'name': worker.fullName},
            ),
      actionLabel: isSuspending
          ? 'workers.suspend_action'.tr()
          : 'workers.unsuspend_action'.tr(),
      actionType: btnConfig.type,
      destructive: btnConfig.destructive,
      cancelLabel: 'workers.cancel'.tr(),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<WorkerActionCubit>().changeStatus(
        workerId: worker.id,
        status: isSuspending ? WorkerStatus.inactive : WorkerStatus.active,
      );
    }
  }

  Future<void> _showDeleteConfirmation({
    required BuildContext context,
    required WorkerEntity worker,
  }) async {
    final confirmed = await showWorkerConfirmationSheet(
      context: context,
      title: 'workers.delete_title'.tr(),
      description: 'workers.delete_description'.tr(
        namedArgs: {'name': worker.fullName},
      ),
      actionLabel: 'workers.delete_action'.tr(),
      actionType: _deleteButton.type,
      destructive: _deleteButton.destructive,
      cancelLabel: 'workers.cancel'.tr(),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<WorkerActionCubit>().delete(worker.id);
    }
  }
}
