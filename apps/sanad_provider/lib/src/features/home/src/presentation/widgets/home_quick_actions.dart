import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_quick_action_tile.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// Home "Quick Actions" section — Figma `6755:26003`.
///
/// All four destinations reuse existing routes/screens; none are invented.
/// Add Service, Invite Member, and New Request are owner-only surfaces with
/// no dedicated backend permission (mirroring
/// `ServiceRoutes.isOwnerOnlyRoute`/`WorkerRoutes.isOwnerOnlyRoute`), so they
/// are gated on `SessionManager.isProviderOwner` — the same check the router
/// itself uses for these routes. Add Branch has a real backend permission
/// (`provider:branch:create`), so it is gated through [PermissionGate]
/// instead, matching the Branches list page's own "Add Branch" button.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isOwner = context.session.isProviderOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          'home.quick_actions_title'.tr(),
          style: typography.regularNormal.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Column(
          spacing: AppSpacing.sm,
          children: [
            if (isOwner)
              HomeQuickActionTile(
                iconAsset: AppSvgs.homeActionAddService,
                label: 'home.action_add_service'.tr(),
                onTap: () => context.push(ServiceRoutes.add),
              ),
            PermissionGate(
              permission: BranchPermissions.create,
              child: HomeQuickActionTile(
                iconAsset: AppSvgs.homeActionAddBranch,
                label: 'home.action_add_branch'.tr(),
                onTap: () => context.push(BranchRoutes.add),
              ),
            ),
            if (isOwner)
              HomeQuickActionTile(
                iconAsset: AppSvgs.homeActionInviteMember,
                label: 'home.action_invite_member'.tr(),
                onTap: () => context.push(WorkerRoutes.add),
              ),
            if (isOwner)
              HomeQuickActionTile(
                iconAsset: AppSvgs.homeActionNewRequest,
                label: 'home.action_new_request'.tr(),
                onTap: () => context.push(ServiceRoutes.requestNew),
              ),
          ],
        ),
      ],
    );
  }
}
