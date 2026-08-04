import 'package:app_assets/app_assets.dart';
import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/src/routes/organization_settings_routes.dart';
import 'package:workers/workers.dart';

/// Organization settings KPI hub — Figma `1563:11097`.
///
/// Logout lives in the account_settings hub, not here.
class OrganizationSettingsPage extends StatelessWidget {
  /// Creates the organization settings KPI list.
  const OrganizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTableRow(
              title: 'branches.company_name'.tr(),
              leading: AppTableLeading.avatar,
              leadingAvatar: const AppAvatar(),
              trailing: AppTableTrailing.icon,
              trailingIcon: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                children: [
                  AppStatCard(
                    icon: AppSvgPicture.asset(
                      AppSvgs.tools,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        colors.palettes.yellow.shade500,
                        BlendMode.srcIn,
                      ),
                    ),
                    iconBackgroundColor: colors.palettes.yellow.shade50,
                    label: 'settings.general_settings'.tr(),
                    actionLabel: 'settings.stat_general_action'.tr(),
                    onActionTap: () =>
                        context.push(OrganizationSettingsRoutes.general),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppStatCard(
                    icon: AppSvgPicture.asset(
                      AppSvgs.users2,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        colors.palettes.sky.shade900,
                        BlendMode.srcIn,
                      ),
                    ),
                    iconBackgroundColor: colors.palettes.accent.shade50,
                    count: 'settings.stat_team_count'.tr(),
                    label: 'settings.stat_team_label'.tr(),
                    actionLabel: 'settings.stat_team_action'.tr(),
                    onActionTap: () => context.push(WorkerRoutes.list),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppStatCard(
                    icon: AppSvgPicture.asset(
                      AppSvgs.pin,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        colors.palettes.dark.shade900,
                        BlendMode.srcIn,
                      ),
                    ),
                    iconBackgroundColor: colors.palettes.main.shade50,
                    count: 'settings.stat_branches_count'.tr(),
                    label: 'settings.stat_branches_label'.tr(),
                    actionLabel: 'settings.stat_branches_action'.tr(),
                    onActionTap: () => context.push(BranchRoutes.list),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppStatCard(
                    icon: AppSvgPicture.asset(
                      AppSvgs.mailOut,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        colors.palettes.sky.shade700,
                        BlendMode.srcIn,
                      ),
                    ),
                    iconBackgroundColor: colors.palettes.sky.shade50,
                    count: 'settings.stat_invitations_count'.tr(),
                    label: 'settings.stat_invitations_label'.tr(),
                    actionLabel: 'settings.stat_invitations_action'.tr(),
                    onActionTap: () => context.push(WorkerRoutes.list),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
