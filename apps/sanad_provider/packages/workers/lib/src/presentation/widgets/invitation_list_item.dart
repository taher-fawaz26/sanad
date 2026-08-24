import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/presentation/widgets/invitation_action_invokers.dart';

/// Swipe-group tag shared by every [InvitationListItem] so only one row's
/// swipe actions stay open at a time — wrap the list in
/// `AppSwipeActionsGroup`.
const invitationSwipeGroupTag = 'invitations';

/// Invitation row — Figma invitation card (`1607:12287`).
///
/// Contextual actions (Copy / Resend / Cancel / Delete) are exposed only via
/// swipe-to-reveal (`AppSwipeActions`) — there is no secondary "more" menu.
/// Which actions are shown is gated by [invitation]'s status, exactly as the
/// previous action sheet gated them. All actions call the exact same
/// `InvitationActionCubit` methods via `invitation_action_invokers.dart`.
class InvitationListItem extends StatelessWidget {
  const InvitationListItem({
    required this.invitation,
    super.key,
    this.hintController,
  });

  final InvitationEntity invitation;

  /// Externally-driven controller for the first-time swipe discoverability
  /// hint (`AppSwipeActionHint`). Only ever supplied for the one row the
  /// hint targets — every other row leaves this null and keeps
  /// `AppSwipeActions`'s default self-owned controller.
  final SlidableController? hintController;

  bool get _canResend => invitation.status != InvitationStatus.accepted;
  bool get _canCancel => invitation.status == InvitationStatus.pending;
  bool get _canDelete => invitation.status == InvitationStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSwipeActions(
      groupTag: invitationSwipeGroupTag,
      controller: hintController,
      actions: [
        AppSwipeAction(
          svgAsset: AppSvgs.invitationCopy,
          semanticLabel: 'workers.invitation_action_copy_link'.tr(),
          onPressed: () =>
              copyInvitationLink(context: context, invitation: invitation),
        ),
        if (_canResend)
          AppSwipeAction(
            svgAsset: AppSvgs.invitationResend,
            semanticLabel: 'workers.invitation_action_resend'.tr(),
            variant: AppSwipeActionVariant.warning,
            onPressed: () => confirmAndResendInvitation(
              context: context,
              invitation: invitation,
            ),
          ),
        if (_canCancel)
          AppSwipeAction(
            svgAsset: AppSvgs.trashBold,
            semanticLabel: 'workers.invitation_action_cancel'.tr(),
            variant: AppSwipeActionVariant.destructive,
            onPressed: () => confirmAndCancelInvitation(
              context: context,
              invitation: invitation,
            ),
          ),
        if (_canDelete)
          AppSwipeAction(
            svgAsset: AppSvgs.trashBold,
            semanticLabel: 'workers.invitation_action_delete'.tr(),
            variant: AppSwipeActionVariant.destructive,
            onPressed: () => confirmAndDeleteInvitation(
              context: context,
              invitation: invitation,
            ),
          ),
      ],
      child: AppEntityListItem(
        title: invitation.fullName,
        caption: invitation.role,
        leading: AppAvatar(
          initials: invitation.initials,
          backgroundColor: colors.primary,
        ),
        badge: _statusBadge(invitation.status),
      ),
    );
  }

  AppStatusBadge _statusBadge(InvitationStatus status) => switch (status) {
    InvitationStatus.pending => AppStatusBadge(
      label: 'workers.invitation_status_pending'.tr(),
      type: AppStatusBadgeType.warning,
      size: AppStatusBadgeSize.dense,
    ),
    InvitationStatus.accepted => AppStatusBadge(
      label: 'workers.invitation_status_accepted'.tr(),
      type: AppStatusBadgeType.success,
      size: AppStatusBadgeSize.dense,
    ),
    InvitationStatus.expired => AppStatusBadge(
      label: 'workers.invitation_status_expired'.tr(),
      type: AppStatusBadgeType.alert,
      size: AppStatusBadgeSize.dense,
    ),
    InvitationStatus.cancelled => AppStatusBadge(
      label: 'workers.invitation_status_cancelled'.tr(),
      type: AppStatusBadgeType.alert,
      size: AppStatusBadgeSize.dense,
    ),
  };
}
