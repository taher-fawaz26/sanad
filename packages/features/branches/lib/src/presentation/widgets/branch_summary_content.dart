import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/utils/branch_type_label.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/maps.dart';

/// Read-only branch summary sections — Figma review/details (`365:14892`).
class BranchSummaryViewModel {
  const BranchSummaryViewModel({
    required this.branchName,
    required this.typeCaption,
    required this.isActive,
    required this.phone,
    required this.isCustomSchedule,
    required this.scheduleItems,
    required this.coverageAreas,
    required this.services,
    required this.teamInitials,
    this.headerTitle,
    this.headerCaption,
    this.position,
    this.address,
    this.managerName,
    this.radiusKm,
    this.teamOverflowCount = 0,
    this.showTeamViewAll = false,
    this.teamCount = 0,
    this.onOpenMaps,
    this.onViewAllServices,
    this.onViewAllTeam,
  });

  final String? headerTitle;
  final String? headerCaption;
  final String branchName;
  final String typeCaption;
  final bool isActive;
  final LatLng? position;
  final String? address;
  final String phone;
  final String? managerName;
  final bool isCustomSchedule;
  final List<GroupedKeyValueItem> scheduleItems;
  final List<String> coverageAreas;
  final double? radiusKm;
  final List<String> services;
  final List<String> teamInitials;
  final int teamOverflowCount;
  final int teamCount;
  final bool showTeamViewAll;
  final Future<void> Function()? onOpenMaps;
  final VoidCallback? onViewAllServices;
  final VoidCallback? onViewAllTeam;

  static BranchSummaryViewModel fromDraft({
    required AddBranchDraft draft,
    required List<BranchAvailabilityEntity> companySchedule,
    String? headerTitle,
    String? headerCaption,
    Future<void> Function()? onOpenMaps,
  }) {
    final schedule = draft.scheduleMode == BranchScheduleMode.custom
        ? draft.customSchedule
        : companySchedule;

    return BranchSummaryViewModel(
      headerTitle: headerTitle,
      headerCaption: headerCaption,
      branchName: draft.branchName,
      typeCaption: branchTypeLabel(draft.branchType),
      isActive: true,
      position: draft.pickedPosition,
      address: draft.branchAddress,
      phone: draft.phone,
      managerName: draft.selectedManager?.fullName,
      isCustomSchedule: draft.scheduleMode == BranchScheduleMode.custom,
      scheduleItems: [
        for (final day in schedule)
          GroupedKeyValueItem(
            title: BranchScheduleFormatter.localizedDay(day.day),
            value: BranchScheduleFormatter.formatAvailability(day),
          ),
      ],
      coverageAreas: draft.servingAreas.map((a) => a.name).toList(),
      radiusKm: draft.coverageRadiusKm,
      services: draft.selectedServices.map((s) => s.name).toList(),
      teamInitials: draft.selectedWorkers.map((w) => w.initials).toList(),
      teamOverflowCount: draft.selectedWorkers.length > 4
          ? draft.selectedWorkers.length - 4
          : 0,
      teamCount: draft.selectedWorkers.length,
      onOpenMaps: onOpenMaps,
    );
  }

  static BranchSummaryViewModel fromEntity({
    required BranchEntity branch,
    required Color closedScheduleColor,
    Future<void> Function()? onOpenMaps,
    VoidCallback? onViewAllServices,
    VoidCallback? onViewAllTeam,
  }) {
    final availability = branch.availability ?? const [];
    final availabilityByDay = {
      for (final entry in availability) entry.day: entry,
    };
    const closedKey = 'branches.details.closed';

    return BranchSummaryViewModel(
      branchName: branch.branchName,
      typeCaption: branchTypeLabel(branch.branchType),
      isActive: branch.isAvailable,
      position: branch.lat != null && branch.lng != null
          ? LatLng(branch.lat!, branch.lng!)
          : null,
      address: branch.displayAddress,
      phone: branch.branchPhone,
      managerName: branch.branchManagerName,
      isCustomSchedule: branch.availabilityMode == BranchAvailabilityMode.custom,
      scheduleItems: [
        for (final day in BranchWeekdays.all)
          _scheduleRow(
            day: day,
            availability: availabilityByDay[day],
            closedLabel: closedKey.tr(),
            closedColor: closedScheduleColor,
          ),
      ],
      coverageAreas: _resolveCoverageAreas(branch),
      radiusKm: branch.radiusKm,
      services: branch.serviceNames ?? const [],
      teamInitials: branch.workers.map((w) => w.initials).toList(),
      teamOverflowCount: branch.workers.length > 4
          ? branch.workers.length - 4
          : 0,
      teamCount: branch.workers.length,
      showTeamViewAll: branch.workers.isNotEmpty,
      onOpenMaps: onOpenMaps,
      onViewAllServices: onViewAllServices,
      onViewAllTeam: onViewAllTeam,
    );
  }

  static List<String> _resolveCoverageAreas(BranchEntity branch) {
    final names = branch.servingAreaNames;
    if (names != null && names.isNotEmpty) return names;
    return branch.servingAreaPlaceIds ?? const [];
  }

  static GroupedKeyValueItem _scheduleRow({
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
}

/// Shared summary body for review and branch details screens.
class BranchSummaryContent extends StatelessWidget {
  const BranchSummaryContent({
    required this.model,
    super.key,
  });

  final BranchSummaryViewModel model;

  static const visibleServiceCount = 3;
  static const _mapHeight = 230.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initial = model.branchName.isNotEmpty
        ? model.branchName[0].toUpperCase()
        : '?';
    final visibleServices = model.services.take(visibleServiceCount).toList();
    final hiddenServiceCount = model.services.length - visibleServices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (model.headerTitle != null)
          AppLargeNavBar(
            title: model.headerTitle!,
            caption: model.headerCaption ?? '',
            useLargeTitleStyle: false,
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppListCard(
            title: model.branchName,
            caption: model.typeCaption,
            leading: AppAvatar(
              initials: initial,
              backgroundColor: colors.primary,
              showStatusDot: true,
            ),
            badge: AppStatusBadge(
              label: model.isActive
                  ? 'branches.status_active'.tr()
                  : 'branches.status_maintenance'.tr(),
              type: model.isActive
                  ? AppStatusBadgeType.success
                  : AppStatusBadgeType.warning,
              size: AppStatusBadgeSize.compact,
            ),
          ),
        ),
        if (model.position != null) ...[
          SizedBox(height: AppSpacing.md),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                height: _mapHeight,
                child: AppGoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: model.position!,
                    zoom: 14,
                  ),
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                ),
              ),
            ),
          ),
        ],
        if (model.address != null && model.address!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppMapLinkCard(
              title: model.address!,
              caption: 'branches.details.open_in_maps'.tr(),
              leading: Icon(Icons.location_on_outlined, color: colors.primary),
              onTap: model.onOpenMaps == null
                  ? null
                  : () => model.onOpenMaps!(),
            ),
          ),
        ],
        AppSection(
          title: 'branches.details.section_contact'.tr(),
          size: AppSectionSize.compact,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppGroupedKeyValueList(
            items: [
              GroupedKeyValueItem(
                title: 'branches.details.branch_phone'.tr(),
                value: model.phone,
              ),
              if (model.managerName != null)
                GroupedKeyValueItem(
                  title: 'branches.add_branch.branch_manager'.tr(),
                  value: model.managerName!,
                ),
            ],
          ),
        ),
        AppSection(
          title: 'branches.details.section_working_hours'.tr(),
          size: AppSectionSize.compact,
          trailing: model.isCustomSchedule
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: model.isCustomSchedule
              ? AppStatusBadge(
                  label: 'branches.details.schedule_custom'.tr(),
                  type: AppStatusBadgeType.info,
                  size: AppStatusBadgeSize.compact,
                )
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppGroupedKeyValueList(items: model.scheduleItems),
        ),
        AppSection(
          title: 'branches.details.section_coverage'.tr(),
          size: AppSectionSize.compact,
          trailing: !model.isActive
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: !model.isActive
              ? Text(
                  'branches.details.coverage_closed'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: colors.error,
                  ),
                )
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: model.coverageAreas.isEmpty
              ? Text(
                  'branches.details.no_serving_areas'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final area in model.coverageAreas)
                      AppChip(label: area, tone: AppChipTone.softNeutral),
                  ],
                ),
        ),
        if (model.radiusKm != null) ...[
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'branches.details.radius_km'.tr(
                namedArgs: {
                  'radius': model.radiusKm!.toStringAsFixed(0),
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
          trailing: hiddenServiceCount > 0 && model.onViewAllServices != null
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: hiddenServiceCount > 0 && model.onViewAllServices != null
              ? GestureDetector(
                  onTap: model.onViewAllServices,
                  child: Text(
                    'branches.details.view_all_services'.tr(
                      namedArgs: {'count': '${model.services.length}'},
                    ),
                    style: context.appTypography.regularNormal.copyWith(
                      color: colors.primary,
                    ),
                  ),
                )
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: model.services.isEmpty
              ? Text(
                  'branches.details.no_services'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : Wrap(
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
                          namedArgs: {'count': '$hiddenServiceCount'},
                        ),
                        tone: AppChipTone.softNeutral,
                      ),
                  ],
                ),
        ),
        AppSection(
          title: 'branches.details.section_team'.tr(),
          size: AppSectionSize.compact,
          trailing: model.showTeamViewAll && model.onViewAllTeam != null
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: model.showTeamViewAll && model.onViewAllTeam != null
              ? GestureDetector(
                  onTap: model.onViewAllTeam,
                  child: Text(
                    'branches.details.view_all_workers'.tr(
                      namedArgs: {'count': '${model.teamCount}'},
                    ),
                    style: context.appTypography.regularNormal.copyWith(
                      color: colors.primary,
                    ),
                  ),
                )
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: model.teamInitials.isEmpty
              ? Text(
                  'branches.details.no_team_members'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : AppAvatarStack(
                  avatars: [
                    for (final initials in model.teamInitials.take(4))
                      AppAvatar(
                        initials: initials,
                        backgroundColor: colors.primary,
                      ),
                  ],
                  overflowCount: model.teamOverflowCount,
                ),
        ),
      ],
    );
  }
}
