import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
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
            showAppSnackbar(
              context: pageContext,
              title: 'workers.coming_soon'.tr(),
            );
          },
        ),
        // Resend Invitation
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
            showAppSnackbar(
              context: pageContext,
              title: 'workers.coming_soon'.tr(),
            );
          },
        ),
        const AppDivider(),
        // Suspend / Unsuspend Worker
        _ActionRow(
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
        _ActionRow(
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
      child: _ConfirmationSheetContent(
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
      child: _ConfirmationSheetContent(
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.svgAsset,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Material(
      color: colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 18,
          ),
          child: Row(
            children: [
              if (svgAsset != null)
                AppSvgPicture.asset(
                  svgAsset!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else if (icon != null)
                Icon(icon, size: 24, color: color),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: typography.regularNormal.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation bottom sheet content for delete/suspend/unsuspend actions.
///
/// Figma `Sheet Content` (`1526:13048`, `1526:13037`, `1526:13026`).
class _ConfirmationSheetContent extends StatelessWidget {
  const _ConfirmationSheetContent({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.buttonType,
    required this.destructive,
    required this.cancelLabel,
  });

  final String title;
  final String description;
  final String actionLabel;
  final AppButtonType buttonType;
  final bool destructive;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: typography.title2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: typography.regularNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: actionLabel,
            type: buttonType,
            destructive: destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            label: cancelLabel,
            type: AppButtonType.outline,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
