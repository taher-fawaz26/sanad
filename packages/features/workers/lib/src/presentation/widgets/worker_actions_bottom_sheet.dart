import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
import 'package:workers/src/presentation/widgets/action_confirmation_sheet.dart';
import 'package:workers/src/routes/worker_routes.dart';

const ({AppButtonType type, bool destructive}) _suspendButton = (
  type: AppButtonType.primary,
  destructive: true,
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
  final bloc = context.read<WorkersBloc>();
  final pageContext = context;

  return showAppBottomSheet<void>(
    context: context,
    padChild: false,
    child: BlocProvider.value(
      value: bloc,
      child: _WorkerActionsSheetBody(
        worker: worker,
        pageContext: pageContext,
      ),
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
    final isSuspended = worker.status == WorkerStatus.suspended;
    final isPending = worker.status == WorkerStatus.pending;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View Details
        AppTableRow(
          title: 'workers.action_view_details'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: Icon(
            Icons.visibility_outlined,
            size: 24,
            color: colors.textPrimary,
          ),
          onTap: () {
            Navigator.of(context).pop();
            pageContext.push(WorkerRoutes.detailsFor(worker.id), extra: worker);
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
          onTap: () {
            Navigator.of(context).pop();
            pageContext.push(
              WorkerRoutes.editWorkerFor(worker.id),
              extra: worker,
            );
          },
        ),
        // Resend Invitation — only relevant while the worker hasn't
        // accepted their invite yet.
        if (isPending)
          AppTableRow(
            title: 'workers.action_resend_invitation'.tr(),
            leading: AppTableLeading.icon,
            leadingIcon: Icon(
              Icons.forward_to_inbox_outlined,
              size: 24,
              color: colors.textPrimary,
            ),
            onTap: () {
              Navigator.of(context).pop();
              if (!pageContext.mounted) return;
              pageContext.read<WorkersBloc>().add(
                InvitationResendEvent(worker.id),
              );
            },
          ),
        const AppDivider(),
        // Suspend / Unsuspend Worker
        SheetActionRow(
          label: isSuspended
              ? 'workers.action_unsuspend'.tr()
              : 'workers.action_suspend'.tr(),
          icon: isSuspended
              ? Icons.play_circle_outline
              : Icons.pause_circle_outline,
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
    final confirmed = await showAppModalSheet<bool>(
      context: context,
      child: ActionConfirmationSheet(
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
        buttonType: btnConfig.type,
        destructive: btnConfig.destructive,
        cancelLabel: 'workers.cancel'.tr(),
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<WorkersBloc>().add(
        WorkerStatusChangedEvent(
          workerId: worker.id,
          status: isSuspending ? WorkerStatus.suspended : WorkerStatus.active,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation({
    required BuildContext context,
    required WorkerEntity worker,
  }) async {
    final confirmed = await showAppModalSheet<bool>(
      context: context,
      child: ActionConfirmationSheet(
        title: 'workers.delete_title'.tr(),
        description: 'workers.delete_description'.tr(
          namedArgs: {'name': worker.fullName},
        ),
        actionLabel: 'workers.delete_action'.tr(),
        buttonType: _deleteButton.type,
        destructive: _deleteButton.destructive,
        cancelLabel: 'workers.cancel'.tr(),
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<WorkersBloc>().add(WorkerDeletedEvent(worker.id));
    }
  }
}
