import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_overview/provider_overview_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:workers/workers.dart';

/// Organization settings KPI hub — Figma `1563:11097`.
///
/// Logout lives in the account_settings hub, not here. Summary counts
/// (branches/team/invitations) come from [ProviderOverviewBloc] —
/// `GET service-provider/overview`.
class OrganizationSettingsPage extends StatelessWidget {
  /// Creates the organization settings KPI list.
  const OrganizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProviderOverviewBloc>(
      create: (_) =>
          sl<ProviderOverviewBloc>()..add(const ProviderOverviewLoaded()),
      child: const _OrganizationSettingsView(),
    );
  }
}

class _OrganizationSettingsView extends StatelessWidget {
  const _OrganizationSettingsView();

  /// First letter of up to the first two words of [name], uppercased —
  /// [AppAvatar]'s placeholder content. `null` falls back to the avatar's
  /// own default rendering.
  String? _initialsOf(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final words = trimmed.split(RegExp(r'\s+')).take(2);
    return words.map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // The business name comes from the auth session's provider profile
    // (BusinessProviderProfileModel — shared shape for individual and
    // company providers), seeded at login and refreshed by any Session
    // update. Falls back to the generic label until the business has a
    // name on file (e.g. fresh onboarding).
    final profile = sl<SessionManager>().profile;
    final businessName = profile is BusinessProviderProfileModel
        ? profile.businessName
        : null;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTableRow(
              title: businessName ?? 'branches.company_name'.tr(),
              leading: AppTableLeading.avatar,
              leadingAvatar: AppAvatar(initials: _initialsOf(businessName)),
              trailing: AppTableTrailing.icon,
              trailingIcon: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: BlocBuilder<ProviderOverviewBloc, ProviderOverviewState>(
                builder: (context, state) {
                  final overview = state.overview;

                  return ListView(
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
                        count: overview?.teamCount.toString(),
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
                        count: overview?.branchesCount.toString(),
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
                        count: overview?.invitationsCount.toString(),
                        label: 'settings.stat_invitations_label'.tr(),
                        actionLabel: 'settings.stat_invitations_action'.tr(),
                        onActionTap: () => context.push(WorkerRoutes.list),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
