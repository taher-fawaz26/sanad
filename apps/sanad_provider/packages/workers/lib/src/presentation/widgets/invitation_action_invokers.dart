import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';

const ({AppButtonVariant variant, AppButtonIntent intent}) _resendButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.warning,
);
const ({AppButtonVariant variant, AppButtonIntent intent}) _cancelButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.destructive,
);
const ({AppButtonVariant variant, AppButtonIntent intent}) _deleteButton = (
  variant: AppButtonVariant.primary,
  intent: AppButtonIntent.destructive,
);

/// Copies [invitation]'s link to the clipboard. No confirmation — matches
/// the previous action-sheet behaviour.
void copyInvitationLink({
  required BuildContext context,
  required InvitationEntity invitation,
}) {
  Clipboard.setData(ClipboardData(text: invitation.invitationLink ?? ''));
  showAppSnackbar(
    context: context,
    title: 'workers.invitation_link_copied'.tr(),
  );
}

/// Confirms then resends [invitation] via [InvitationActionCubit].
///
/// Shared by any invocation surface (previously the actions bottom sheet,
/// now `AppSwipeActions`) so they run the exact same confirmation +
/// business logic.
Future<void> confirmAndResendInvitation({
  required BuildContext context,
  required InvitationEntity invitation,
}) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'workers.invitation_resend_title'.tr(),
    description: 'workers.invitation_resend_description'.tr(
      namedArgs: {'name': invitation.fullName},
    ),
    actionLabel: 'common.resend'.tr(),
    actionVariant: _resendButton.variant,
    actionIntent: _resendButton.intent,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<InvitationActionCubit>().resend(invitation.id);
  }
}

/// Confirms then cancels [invitation] via [InvitationActionCubit].
Future<void> confirmAndCancelInvitation({
  required BuildContext context,
  required InvitationEntity invitation,
}) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'workers.invitation_cancel_title'.tr(),
    description: 'workers.invitation_cancel_description'.tr(
      namedArgs: {'name': invitation.fullName},
    ),
    actionLabel: 'workers.invitation_cancel_action'.tr(),
    actionVariant: _cancelButton.variant,
    actionIntent: _cancelButton.intent,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<InvitationActionCubit>().cancel(invitation.id);
  }
}

/// Confirms then deletes [invitation] via [InvitationActionCubit].
Future<void> confirmAndDeleteInvitation({
  required BuildContext context,
  required InvitationEntity invitation,
}) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'workers.invitation_delete_title'.tr(),
    description: 'workers.invitation_delete_description'.tr(
      namedArgs: {'name': invitation.fullName},
    ),
    actionLabel: 'common.delete'.tr(),
    actionVariant: _deleteButton.variant,
    actionIntent: _deleteButton.intent,
    cancelLabel: 'common.cancel'.tr(),
  );

  if ((confirmed ?? false) && context.mounted) {
    await context.read<InvitationActionCubit>().delete(invitation.id);
  }
}
