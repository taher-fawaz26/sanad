import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/widgets/action_confirmation_sheet.dart';

const ({AppButtonType type, bool destructive}) _resendButton = (
  type: AppButtonType.warning,
  destructive: false,
);
const ({AppButtonType type, bool destructive}) _cancelButton = (
  type: AppButtonType.primary,
  destructive: true,
);
const ({AppButtonType type, bool destructive}) _deleteButton = (
  type: AppButtonType.primary,
  destructive: true,
);

/// Figma invitation actions bottom sheet (`1607:12699`).
Future<void> showInvitationActionsBottomSheet({
  required BuildContext context,
  required InvitationEntity invitation,
}) {
  final cubit = context.read<InvitationActionCubit>();
  final pageContext = context;

  return SheetNavigator.push<void>(
    context,
    BlocProvider.value(
      value: cubit,
      child: _InvitationActionsSheetBody(
        invitation: invitation,
        pageContext: pageContext,
      ),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.expanded,
      padChild: false,
    ),
  );
}

class _InvitationActionsSheetBody extends StatelessWidget {
  const _InvitationActionsSheetBody({
    required this.invitation,
    required this.pageContext,
  });

  final InvitationEntity invitation;
  final BuildContext pageContext;

  bool get _canCancel => invitation.status == InvitationStatus.pending;
  bool get _canDelete => invitation.status == InvitationStatus.cancelled;
  bool get _canResend => invitation.status != InvitationStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTableRow(
          title: 'workers.invitation_action_copy_link'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: AppSvgPicture.asset(
            AppSvgs.invitationCopy,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
          onTap: () {
            Navigator.of(context).pop();
            if (!pageContext.mounted) return;
            Clipboard.setData(
              ClipboardData(text: invitation.invitationLink ?? ''),
            );
            showAppSnackbar(
              context: pageContext,
              title: 'workers.invitation_link_copied'.tr(),
            );
          },
        ),
        if (_canResend)
          AppTableRow(
            title: 'workers.invitation_action_resend'.tr(),
            leading: AppTableLeading.icon,
            leadingIcon: AppSvgPicture.asset(
              AppSvgs.invitationResend,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              if (!pageContext.mounted) return;
              await _showResendConfirmation(context: pageContext);
            },
          ),
        if (_canCancel || _canDelete) const AppDivider(),
        if (_canCancel)
          SheetActionRow(
            label: 'workers.invitation_action_cancel'.tr(),
            svgAsset: AppSvgs.trashBold,
            color: colors.error,
            onTap: () async {
              Navigator.of(context).pop();
              if (!pageContext.mounted) return;
              await _showCancelConfirmation(context: pageContext);
            },
          ),
        if (_canDelete)
          SheetActionRow(
            label: 'workers.invitation_action_delete'.tr(),
            svgAsset: AppSvgs.trashBold,
            color: colors.error,
            onTap: () async {
              Navigator.of(context).pop();
              if (!pageContext.mounted) return;
              await _showDeleteConfirmation(context: pageContext);
            },
          ),
      ],
    );
  }

  Future<void> _showResendConfirmation({required BuildContext context}) async {
    final confirmed = await showWorkerConfirmationSheet(
      context: context,
      title: 'workers.invitation_resend_title'.tr(),
      description: 'workers.invitation_resend_description'.tr(
        namedArgs: {'name': invitation.fullName},
      ),
      actionLabel: 'workers.invitation_resend_action'.tr(),
      actionType: _resendButton.type,
      destructive: _resendButton.destructive,
      cancelLabel: 'workers.cancel'.tr(),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<InvitationActionCubit>().resend(invitation.id);
    }
  }

  Future<void> _showCancelConfirmation({required BuildContext context}) async {
    final confirmed = await showWorkerConfirmationSheet(
      context: context,
      title: 'workers.invitation_cancel_title'.tr(),
      description: 'workers.invitation_cancel_description'.tr(
        namedArgs: {'name': invitation.fullName},
      ),
      actionLabel: 'workers.invitation_cancel_action'.tr(),
      actionType: _cancelButton.type,
      destructive: _cancelButton.destructive,
      cancelLabel: 'workers.cancel'.tr(),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<InvitationActionCubit>().cancel(invitation.id);
    }
  }

  Future<void> _showDeleteConfirmation({required BuildContext context}) async {
    final confirmed = await showWorkerConfirmationSheet(
      context: context,
      title: 'workers.invitation_delete_title'.tr(),
      description: 'workers.invitation_delete_description'.tr(
        namedArgs: {'name': invitation.fullName},
      ),
      actionLabel: 'workers.invitation_delete_action'.tr(),
      actionType: _deleteButton.type,
      destructive: _deleteButton.destructive,
      cancelLabel: 'workers.cancel'.tr(),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<InvitationActionCubit>().delete(invitation.id);
    }
  }
}
