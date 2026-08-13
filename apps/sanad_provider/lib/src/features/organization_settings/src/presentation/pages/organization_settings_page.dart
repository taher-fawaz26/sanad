import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_completion/provider_completion_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_overview/provider_overview_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_card.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_stages.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:services/services.dart';
import 'package:shared_ui/shared_ui.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProviderOverviewBloc>(
          create: (_) =>
              sl<ProviderOverviewBloc>()..add(const ProviderOverviewLoaded()),
        ),
        BlocProvider<ProviderCompletionBloc>(
          create: (_) =>
              sl<ProviderCompletionBloc>()
                ..add(const ProviderCompletionLoaded()),
        ),
      ],
      child: const _OrganizationSettingsView(),
    );
  }
}

/// Realistic mock used only to skeletonize the real setup card via
/// [AppSkeletonizer] — no bespoke skeleton layout.
final _skeletonCompletion = ProviderCompletionEntity(
  percentage: 40,
  requiredCompleted: 2,
  requiredTotal: 5,
  visibleToCustomers: false,
  items: [
    for (final id in ProviderCompletionItemId.values)
      ProviderCompletionItemEntity(
        id: id,
        label: BoneMock.words(2),
        completed: false,
        required: true,
      ),
  ],
);

/// Re-fetches both KPI-hub sections — dispatched after returning from any
/// action that could change setup completion or the overview counts (add
/// branch, invite/edit worker, edit business profile, add service).
void _refreshHub(BuildContext context) {
  context.read<ProviderOverviewBloc>().add(const ProviderOverviewRefreshed());
  context.read<ProviderCompletionBloc>().add(
    const ProviderCompletionRefreshed(),
  );
}

class _OrganizationSettingsView extends StatelessWidget {
  const _OrganizationSettingsView();

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
      appBar: AppNavBar(
        title: businessName ?? 'branches.company_name'.tr(),
        trailingAction: AppNavBarTrailingAction.icon,
        trailing: AppNotificationIcon(
          hasUnread: true,
          onTap: () {},
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          children: [
            BlocBuilder<ProviderCompletionBloc, ProviderCompletionState>(
              builder: (context, state) {
                final completion = state.completion;
                if (completion != null) {
                  return OrganizationSetupCard(
                    completion: completion,
                    onStageAction: (id) => _onSetupStageAction(context, id),
                  );
                }
                if (state.hasError) {
                  return _SetupError(
                    failure: state.failure,
                    onRetry: () => context.read<ProviderCompletionBloc>().add(
                      const ProviderCompletionLoaded(),
                    ),
                  );
                }
                // Skeletonize the *real* setup card with mock data instead
                // of a bespoke skeleton layout.
                return AppSkeletonizer(
                  enabled: true,
                  child: OrganizationSetupCard(
                    completion: _skeletonCompletion,
                    onStageAction: (_) {},
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.lg),
            BlocBuilder<ProviderOverviewBloc, ProviderOverviewState>(
              builder: (context, state) {
                final overview = state.overview;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      onActionTap: () => _pushAndRefresh(
                        context,
                        OrganizationSettingsRoutes.general,
                      ),
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
                      onActionTap: () =>
                          _pushAndRefresh(context, WorkerRoutes.list),
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
                      onActionTap: () =>
                          _pushAndRefresh(context, BranchRoutes.list),
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
                      onActionTap: () =>
                          _pushAndRefresh(context, WorkerRoutes.list),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Pushes [route] and refreshes both hub sections on return — the target
/// screens (General Settings, Team, Branches, Invitations) can change the
/// overview counts and/or setup completion.
Future<void> _pushAndRefresh(BuildContext context, String route) async {
  await context.push<Object?>(route);
  if (context.mounted) _refreshHub(context);
}

/// Routes an incomplete setup stage's "Add" tap to the matching feature,
/// then refreshes both hub sections on return.
void _onSetupStageAction(BuildContext context, OrganizationSetupStageId id) {
  final route = switch (id) {
    OrganizationSetupStageId.businessProfile =>
      OrganizationSettingsRoutes.general,
    OrganizationSetupStageId.firstBranch => BranchRoutes.list,
    OrganizationSetupStageId.firstTeam => WorkerRoutes.list,
    OrganizationSetupStageId.grow => ServiceRoutes.list,
  };
  unawaited(_pushAndRefresh(context, route));
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(color: context.appColors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppErrorState(
          style: display.isConnectivity
              ? AppErrorStateStyle.network
              : AppErrorStateStyle.generic,
          title: display.title,
          description: display.description,
          retryLabel: failureRetryLabel(),
          onRetry: display.isRetryable ? onRetry : null,
        ),
      ),
    );
  }
}
