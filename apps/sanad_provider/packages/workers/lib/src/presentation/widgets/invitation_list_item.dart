import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/presentation/widgets/invitation_actions_bottom_sheet.dart';

/// Invitation row — Figma invitation card (`1607:12287`).
class InvitationListItem extends StatelessWidget {
  const InvitationListItem({required this.invitation, super.key});

  final InvitationEntity invitation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppEntityListItem(
      title: invitation.fullName,
      caption: invitation.role,
      leading: AppAvatar(
        initials: invitation.initials,
        backgroundColor: colors.primary,
      ),
      badge: _statusBadge(invitation.status),
      trailing: Semantics(
        label: 'workers.more_actions'.tr(),
        child: AppIconButton(
          icon: Icons.more_vert,
          iconColor: colors.textPrimary,
          onTap: () => showInvitationActionsBottomSheet(
            context: context,
            invitation: invitation,
          ),
        ),
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
