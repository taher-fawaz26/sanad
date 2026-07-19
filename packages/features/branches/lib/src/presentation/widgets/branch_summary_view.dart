import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Normalized data for [BranchSummaryView], shared by the add-branch review
/// screen (draft source) and the branch details screen (saved-branch source).
class BranchSummaryData {
  const BranchSummaryData({
    required this.title,
    required this.badgeLabel,
    required this.badgeType,
    required this.phone,
    required this.schedule,
    required this.areaNames,
    required this.serviceNames,
    required this.workerInitials,
    this.caption,
    this.position,
    this.address,
    this.managerName,
    this.isCustomSchedule = false,
  });

  final String title;
  final String? caption;
  final String badgeLabel;
  final AppStatusBadgeType badgeType;
  final LatLng? position;
  final String? address;
  final String phone;
  final String? managerName;
  final bool isCustomSchedule;
  final List<BranchAvailabilityEntity> schedule;
  final List<String> areaNames;
  final List<String> serviceNames;
  final List<String> workerInitials;
}

/// Shared summary layout for a branch — header, map preview, contact, working
/// hours, coverage, services and team sections.
///
/// Figma `review` (`365:14892`) — reused by the branch details screen with a
/// different footer action.
class BranchSummaryView extends StatelessWidget {
  const BranchSummaryView({
    required this.data,
    this.onOpenMaps,
    this.onViewAllServices,
    this.onViewAllWorkers,
    super.key,
  });

  static const _visibleServiceCount = 3;
  static const _visibleTeamCount = 4;

  final BranchSummaryData data;
  final VoidCallback? onOpenMaps;
  final VoidCallback? onViewAllServices;
  final VoidCallback? onViewAllWorkers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(data: data),
          if (data.position != null) ...[
            SizedBox(height: AppSpacing.md),
            _MapPreview(
              position: data.position!,
              address: data.address ?? '',
              onOpenMaps: onOpenMaps,
            ),
          ],
          _ContactSection(data: data),
          _WorkingHoursSection(data: data),
          _CoverageSection(areaNames: data.areaNames),
          _ServicesSection(
            serviceNames: data.serviceNames,
            visibleCount: _visibleServiceCount,
            onViewAll: onViewAllServices,
          ),
          _TeamSection(
            initials: data.workerInitials,
            visibleCount: _visibleTeamCount,
            onViewAll: onViewAllWorkers,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final BranchSummaryData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final initial = data.title.isNotEmpty ? data.title[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppAvatar(
            initials: initial,
            backgroundColor: colors.primary,
            showStatusDot: true,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: typography.regularNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.caption != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    data.caption!,
                    style: typography.smallNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          AppStatusBadge(
            label: data.badgeLabel,
            type: data.badgeType,
            size: AppStatusBadgeSize.compact,
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.position,
    required this.address,
    this.onOpenMaps,
  });

  final LatLng position;
  final String address;
  final VoidCallback? onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: responsiveDimension(180),
              child: AbsorbPointer(
                child: AppGoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: position,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('branch-summary'),
                      position: position,
                    ),
                  },
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  compassEnabled: false,
                ),
              ),
            ),
          ),
          if (address.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              address,
              style: typography.regularNormal.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: onOpenMaps,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'branches.details.open_in_maps'.tr(),
              style: typography.smallNormal.copyWith(color: colors.link),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.data});

  final BranchSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                value: data.phone,
              ),
              if (data.managerName != null)
                GroupedKeyValueItem(
                  title: 'branches.review.manager'.tr(),
                  value: data.managerName!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkingHoursSection extends StatelessWidget {
  const _WorkingHoursSection({required this.data});

  final BranchSummaryData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final closedLabel = 'branches.details.closed'.tr();
    final byDay = {for (final entry in data.schedule) entry.day: entry};

    final items = [
      for (final day in BranchWeekdays.all)
        _scheduleItem(day, byDay[day], closedLabel, colors.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_working_hours'.tr(),
          size: AppSectionSize.compact,
          trailing: data.isCustomSchedule
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: data.isCustomSchedule
              ? AppStatusBadge(
                  label: 'branches.details.schedule_custom'.tr(),
                  type: AppStatusBadgeType.info,
                  size: AppStatusBadgeSize.compact,
                )
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppGroupedKeyValueList(items: items),
        ),
      ],
    );
  }

  GroupedKeyValueItem _scheduleItem(
    String day,
    BranchAvailabilityEntity? availability,
    String closedLabel,
    Color closedColor,
  ) {
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

class _CoverageSection extends StatelessWidget {
  const _CoverageSection({required this.areaNames});

  final List<String> areaNames;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_coverage'.tr(),
          size: AppSectionSize.compact,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: areaNames.isEmpty
              ? Text(
                  'branches.details.no_serving_areas'.tr(),
                  style: context.appTypography.smallNormal.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final area in areaNames)
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
                ),
        ),
      ],
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({
    required this.serviceNames,
    required this.visibleCount,
    this.onViewAll,
  });

  final List<String> serviceNames;
  final int visibleCount;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = serviceNames.take(visibleCount).toList();
    final hidden = serviceNames.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_services'.tr(),
          size: AppSectionSize.compact,
          trailing: serviceNames.isEmpty
              ? AppSectionTrailing.none
              : AppSectionTrailing.custom,
          trailingWidget: serviceNames.isEmpty
              ? null
              : _ViewAllLink(
                  label: 'branches.review.view_all'.tr(
                    namedArgs: {'count': '${serviceNames.length}'},
                  ),
                  onTap: onViewAll,
                ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: serviceNames.isEmpty
              ? Text(
                  'branches.review.no_services'.tr(),
                  style: context.appTypography.smallNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final service in visible)
                      AppChip(label: service, tone: AppChipTone.softNeutral),
                    if (hidden > 0)
                      AppChip(
                        label: 'branches.details.services_more'.tr(
                          namedArgs: {'count': '$hidden'},
                        ),
                        tone: AppChipTone.softNeutral,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.initials,
    required this.visibleCount,
    this.onViewAll,
  });

  final List<String> initials;
  final int visibleCount;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overflow = initials.length - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_team'.tr(),
          size: AppSectionSize.compact,
          trailing: initials.isEmpty
              ? AppSectionTrailing.none
              : AppSectionTrailing.custom,
          trailingWidget: initials.isEmpty
              ? null
              : _ViewAllLink(
                  label: 'branches.review.workers_count'.tr(
                    namedArgs: {'count': '${initials.length}'},
                  ),
                  onTap: onViewAll,
                ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: initials.isEmpty
              ? Text(
                  'branches.details.no_team_members'.tr(),
                  style: context.appTypography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : AppAvatarStack(
                  avatars: [
                    for (final value in initials.take(visibleCount))
                      AppAvatar(
                        initials: value,
                        backgroundColor: colors.primary,
                      ),
                  ],
                  overflowCount: overflow > 0 ? overflow : 0,
                ),
        ),
      ],
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: context.appTypography.regularNormal.copyWith(
        color: context.appColors.primary,
      ),
    );
    if (onTap == null) return text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: text,
    );
  }
}
