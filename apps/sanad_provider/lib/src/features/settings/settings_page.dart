import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invitation/invitation.dart';
import 'package:workers/workers.dart';

/// Figma `setting` (`1546:8548`) — Organization Settings dashboard.
class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({super.key});

  @override
  State<ProviderSettingsPage> createState() => _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends State<ProviderSettingsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccessState) {
          context.go(AuthRoutes.login);
        }
      },
      child: Scaffold(
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: AppSegmentedControl(
                  segments: [
                    'settings.tab_organization'.tr(),
                    'settings.tab_settings'.tr(),
                  ],
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? const _OrganizationSettingsTab()
                    : const _SettingsPlaceholderTab(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: AppButton(
                  label: 'settings.logout'.tr(),
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLogoutEvent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationSettingsTab extends StatelessWidget {
  const _OrganizationSettingsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
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
        SizedBox(height: AppSpacing.md),
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
        SizedBox(height: AppSpacing.md),
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
        SizedBox(height: AppSpacing.md),
        AppStatCard(
          icon: AppSvgPicture.asset(
            AppSvgs.bag,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              colors.palettes.yellow.shade700,
              BlendMode.srcIn,
            ),
          ),
          iconBackgroundColor: colors.palettes.yellow.shade50,
          count: 'settings.stat_services_count'.tr(),
          label: 'settings.stat_services_label'.tr(),
          actionLabel: 'settings.stat_services_action'.tr(),
          onActionTap: () => showAppSnackbar(
            context: context,
            title: 'settings.coming_soon'.tr(),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        // TEMPORARY — demo entry point for the invitation flow UI while
        // deep-link handling is not yet implemented. Remove once the real
        // invitation email deep link replaces this shortcut.
        AppStatCard(
          icon: AppSvgPicture.asset(
            AppSvgs.mailOut,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              colors.palettes.main.shade700,
              BlendMode.srcIn,
            ),
          ),
          iconBackgroundColor: colors.palettes.main.shade50,
          count: 'settings.stat_invitation_demo_count'.tr(),
          label: 'settings.stat_invitation_demo_label'.tr(),
          actionLabel: 'settings.stat_invitation_demo_action'.tr(),
          onActionTap: () => context.push(InvitationRoutes.details),
        ),
      ],
    );
  }
}

class _SettingsPlaceholderTab extends StatelessWidget {
  const _SettingsPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppGenericEmptyState(
        title: 'settings.placeholder_title'.tr(),
        description: 'settings.placeholder_description'.tr(),
      ),
    );
  }
}
