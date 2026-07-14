import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/data/branch_details_static_data.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
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
    return BlocBuilder<BranchDetailsBloc, BranchDetailsState>(
      builder: (context, state) {
        if (state.isLoading && state.branch == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.hasError && state.branch == null) {
          return _BranchDetailsError(
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
  const _BranchDetailsError({required this.onRetry, required this.onClose});

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
              child: Center(
                child: AppGenericEmptyState(
                  title: 'empty_states.network_title'.tr(),
                  description: 'empty_states.network_description'.tr(),
                  actionLabel: 'empty_states.retry'.tr(),
                  onAction: onRetry,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final visibleServices =
        BranchDetailsStaticData.services.take(_visibleServiceCount).toList();
    final hiddenServiceCount =
        BranchDetailsStaticData.services.length - visibleServices.length;
    final teamCount = BranchDetailsStaticData.teamInitials.length;
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
                      trailing: branch.availabilityMode == 'CUSTOM'
                          ? AppSectionTrailing.custom
                          : AppSectionTrailing.none,
                      trailingWidget: branch.availabilityMode == 'CUSTOM'
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
                              style: context.appTypography.regularNormal.copyWith(
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
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                      trailingWidget: GestureDetector(
                        onTap: () => _showComingSoon(
                          context,
                          'branches.details.manage_team_coming_soon'.tr(),
                        ),
                        child: Text(
                          'branches.details.view_all_workers'.tr(
                            namedArgs: {'count': '$teamCount'},
                          ),
                          style: context.appTypography.regularNormal.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        children: [
                          AppAvatarStack(
                            avatars: [
                              for (final initials
                                  in BranchDetailsStaticData.teamInitials
                                      .take(_visibleTeamCount))
                                AppAvatar(
                                  initials: initials,
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
                              'branches.details.manage_team_coming_soon'.tr(),
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
    final ids = branch.servingAreaPlaceIds;
    if (ids == null || ids.isEmpty) {
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
        for (final placeId in ids)
          AppChip(
            label: placeId,
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
    showAppActionSheet(
      context: context,
      items: [
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
