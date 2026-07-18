import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Figma Branch Details screen (`194:2647`).
class BranchDetailsPage extends StatelessWidget {
  const BranchDetailsPage({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchDetailsBloc, BranchDetailsState>(
      listenWhen: (prev, curr) =>
          prev.statusUpdateFailure != curr.statusUpdateFailure &&
          curr.statusUpdateFailure != null,
      listener: (context, state) {
        showAppSnackbar(
          context: context,
          title:
              state.statusUpdateFailure?.message ??
              'branches.details.status_update_error'.tr(),
        );
      },
      builder: (context, state) {
        if (state.isLoading && state.branch == null) {
          return const Scaffold(
            body: Center(child: AppLoadingIndicator()),
          );
        }

        if (state.hasError && state.branch == null) {
          return _BranchDetailsError(
            failure: state.failure,
            onRetry: () => context.read<BranchDetailsBloc>().add(
              const BranchDetailsRefreshEvent(),
            ),
            onClose: () => context.pop(),
          );
        }

        final branch = state.branch;
        if (branch == null) {
          return const SizedBox.shrink();
        }

        return _BranchDetailsContent(branch: branch);
      },
    );
  }
}

class _BranchDetailsError extends StatelessWidget {
  const _BranchDetailsError({
    required this.onRetry,
    required this.onClose,
    this.failure,
  });

  final Failure? failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: onClose),
            ),
            Expanded(
              child: Center(child: _errorContent()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorContent() {
    final retryLabel = 'empty_states.retry'.tr();
    final f = failure;

    if (f is NoInternetFailure || f is NetworkFailure) {
      return AppNetworkFailureState(
        title: 'empty_states.network_title'.tr(),
        description: 'empty_states.network_description'.tr(),
        retryLabel: retryLabel,
        onRetry: onRetry,
      );
    }

    if (f is TimeoutFailure) {
      return AppNetworkFailureState(
        title: 'empty_states.timeout_title'.tr(),
        description: 'empty_states.timeout_description'.tr(),
        retryLabel: retryLabel,
        onRetry: onRetry,
      );
    }

    final description = (f != null && f.message.isNotEmpty)
        ? f.message.tr()
        : 'empty_states.server_error_description'.tr();

    return AppGenericEmptyState(
      title: 'empty_states.server_error_title'.tr(),
      description: description,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

class _BranchDetailsContent extends StatelessWidget {
  const _BranchDetailsContent({required this.branch});

  final BranchEntity branch;

  static const _visibleServiceCount = 3;
  static const _visibleTeamCount = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initial = branch.branchName.isNotEmpty
        ? branch.branchName[0].toUpperCase()
        : '?';
    final managerCaption = branch.branchManagerName == null
        ? null
        : 'branches.details.manager_caption'.tr(
            namedArgs: {'name': branch.branchManagerName!},
          );
    final scheduleItems = _buildScheduleItems(context);
    final services = branch.serviceNames ?? const <String>[];
    final visibleServices = services.take(_visibleServiceCount).toList();
    final hiddenServiceCount = services.length - visibleServices.length;
    final workers = branch.workers;
    final teamCount = workers.length;
    final overflowTeamCount = teamCount - _visibleTeamCount;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: () => context.pop()),
              trailingAction: AppNavBarTrailingAction.icon,
              trailing: Icon(
                Icons.more_vert,
                size: 24,
                color: colors.textPrimary,
              ),
              onTrailingTap: () => _showMoreActions(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AppListCard(
                        title: branch.branchName,
                        caption: managerCaption ?? branch.displayAddress,
                        leading: AppAvatar(
                          initials: initial,
                          backgroundColor: colors.primary,
                          showStatusDot: true,
                        ),
                        badge: AppStatusBadge(
                          label: branch.isAvailable
                              ? 'branches.status_active'.tr()
                              : 'branches.status_maintenance'.tr(),
                          type: branch.isAvailable
                              ? AppStatusBadgeType.success
                              : AppStatusBadgeType.warning,
                          size: AppStatusBadgeSize.compact,
                        ),
                      ),
                    ),
                    AppSection(
                      title: 'branches.details.section_contact'.tr(),
                      size: AppSectionSize.compact,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          AppMapLinkCard(
                            title: branch.displayAddress,
                            caption: 'branches.details.open_in_maps'.tr(),
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: colors.primary,
                            ),
                            onTap: () => _openMaps(context),
                          ),
                          SizedBox(height: AppSpacing.md),
                          AppGroupedKeyValueList(
                            items: [
                              GroupedKeyValueItem(
                                title: 'branches.details.branch_phone'.tr(),
                                value: branch.branchPhone,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSection(
                      title: 'branches.details.section_working_hours'.tr(),
                      size: AppSectionSize.compact,
                      trailing:
                          branch.availabilityMode ==
                              BranchAvailabilityMode.custom
                          ? AppSectionTrailing.custom
                          : AppSectionTrailing.none,
                      trailingWidget:
                          branch.availabilityMode ==
                              BranchAvailabilityMode.custom
                          ? AppStatusBadge(
                              label: 'branches.details.schedule_custom'.tr(),
                              type: AppStatusBadgeType.info,
                              size: AppStatusBadgeSize.compact,
                            )
                          : null,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AppGroupedKeyValueList(items: scheduleItems),
                    ),
                    AppSection(
                      title: 'branches.details.section_coverage'.tr(),
                      size: AppSectionSize.compact,
                      trailing: !branch.isAvailable
                          ? AppSectionTrailing.custom
                          : AppSectionTrailing.none,
                      trailingWidget: !branch.isAvailable
                          ? Text(
                              'branches.details.coverage_closed'.tr(),
                              style: context.appTypography.regularNormal
                                  .copyWith(
                                    color: colors.error,
                                  ),
                            )
                          : null,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _buildCoverageChips(context),
                    ),
                    if (branch.radiusKm != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          'branches.details.radius_km'.tr(
                            namedArgs: {
                              'radius': branch.radiusKm!.toStringAsFixed(0),
                            },
                          ),
                          style: context.appTypography.regularNormal.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    AppSection(
                      title: 'branches.details.section_services'.tr(),
                      size: AppSectionSize.compact,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final service in visibleServices)
                            AppChip(
                              label: service,
                              tone: AppChipTone.softNeutral,
                            ),
                          if (hiddenServiceCount > 0)
                            AppChip(
                              label: 'branches.details.services_more'.tr(
                                namedArgs: {
                                  'count': '$hiddenServiceCount',
                                },
                              ),
                              tone: AppChipTone.softNeutral,
                            ),
                        ],
                      ),
                    ),
                    AppSection(
                      title: 'branches.details.section_team'.tr(),
                      size: AppSectionSize.compact,
                      trailing: AppSectionTrailing.custom,
                      trailingWidget: workers.isEmpty
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: () => _showComingSoon(
                                context,
                                'branches.details.manage_team_coming_soon'.tr(),
                              ),
                              child: Text(
                                'branches.details.view_all_workers'.tr(
                                  namedArgs: {'count': '$teamCount'},
                                ),
                                style: context.appTypography.regularNormal
                                    .copyWith(color: colors.primary),
                              ),
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: workers.isEmpty
                          ? Text(
                              'branches.details.no_team_members'.tr(),
                              style: context.appTypography.regularNormal
                                  .copyWith(color: colors.textSecondary),
                            )
                          : Row(
                              children: [
                                AppAvatarStack(
                                  avatars: [
                                    for (final worker in workers.take(
                                      _visibleTeamCount,
                                    ))
                                      AppAvatar(
                                        initials: worker.initials,
                                        backgroundColor: colors.primary,
                                      ),
                                  ],
                                  overflowCount: overflowTeamCount > 0
                                      ? overflowTeamCount
                                      : 0,
                                ),
                                const Spacer(),
                                AppButtonPresets.outline(
                                  label: 'branches.details.manage_team'.tr(),
                                  size: AppButtonSize.small,
                                  onPressed: () => _showComingSoon(
                                    context,
                                    'branches.details.manage_team_coming_soon'
                                        .tr(),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: AppButton(
                label: 'branches.details.edit_branch'.tr(),
                onPressed: () => _showComingSoon(
                  context,
                  'branches.details.edit_coming_soon'.tr(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageChips(BuildContext context) {
    final colors = context.appColors;
    // Prefer human-readable names from the API; fall back to place IDs.
    final names = branch.servingAreaNames;
    final areas = (names?.isNotEmpty ?? false)
        ? names!
        : branch.servingAreaPlaceIds ?? const <String>[];
    if (areas.isEmpty) {
      return Text(
        'branches.details.no_serving_areas'.tr(),
        style: context.appTypography.smallNormal.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final area in areas)
          AppChip(
            label: area,
            tone: AppChipTone.softSuccess,
            icon: Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colors.palettes.main.shade700,
            ),
            iconPosition: AppChipIconPosition.left,
          ),
      ],
    );
  }

  List<GroupedKeyValueItem> _buildScheduleItems(BuildContext context) {
    final colors = context.appColors;
    final closedLabel = 'branches.details.closed'.tr();
    final closedColor = colors.error;
    final availability = branch.availability ?? const [];
    final availabilityByDay = {
      for (final entry in availability) entry.day: entry,
    };

    return [
      for (final day in BranchWeekdays.all)
        _scheduleRow(
          day: day,
          availability: availabilityByDay[day],
          closedLabel: closedLabel,
          closedColor: closedColor,
        ),
    ];
  }

  GroupedKeyValueItem _scheduleRow({
    required String day,
    required BranchAvailabilityEntity? availability,
    required String closedLabel,
    required Color closedColor,
  }) {
    final hasSlots = availability != null && availability.slots.isNotEmpty;
    return GroupedKeyValueItem(
      title: BranchScheduleFormatter.localizedDay(day),
      value: hasSlots
          ? BranchScheduleFormatter.formatAvailability(availability)
          : closedLabel,
      valueColor: hasSlots ? null : closedColor,
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final opened = await BranchMapsLauncher.openBranchLocation(branch);
    if (!context.mounted) return;
    if (!opened) {
      showAppSnackbar(
        context: context,
        title: 'branches.details.maps_unavailable'.tr(),
      );
    }
  }

  void _showMoreActions(BuildContext context) {
    final isActive = branch.isAvailable;
    final bloc = context.read<BranchDetailsBloc>();
    showAppActionSheet<void>(
      context: context,
      items: [
        AppActionSheetItem(
          label: isActive
              ? 'branches.details.action_set_maintenance'.tr()
              : 'branches.details.action_set_active'.tr(),
          leading: Icon(
            isActive ? Icons.pause_circle_outline : Icons.check_circle_outline,
          ),
          onTap: () {
            Navigator.of(context).pop();
            bloc.add(BranchStatusToggleEvent(isAvailable: !isActive));
          },
        ),
        AppActionSheetItem(
          label: 'branches.details.action_edit'.tr(),
          leading: const Icon(Icons.edit_outlined),
          onTap: () {
            Navigator.of(context).pop();
            _showComingSoon(
              context,
              'branches.details.edit_coming_soon'.tr(),
            );
          },
        ),
        AppActionSheetItem(
          label: 'branches.details.action_delete'.tr(),
          leading: const Icon(Icons.delete_outline),
          isDestructive: true,
          onTap: () {
            Navigator.of(context).pop();
            _showComingSoon(
              context,
              'branches.details.delete_coming_soon'.tr(),
            );
          },
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    showAppSnackbar(context: context, title: message);
  }
}
