import 'package:app_assets/app_assets.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Localized label for a [BranchType]. Shared by the branch details "Branch
/// Info" section and the add-branch review header caption.
String branchTypeLabel(BranchType type) => switch (type) {
  BranchType.mainBranch => 'branches.add_branch.branch_type_main_branch'.tr(),
  BranchType.headquarters =>
    'branches.add_branch.branch_type_headquarters'.tr(),
  BranchType.mainStore => 'branches.add_branch.branch_type_main_store'.tr(),
  BranchType.warehouse => 'branches.add_branch.branch_type_warehouse'.tr(),
};

/// Editable sections of [BranchSummaryView]. Used to target a specific
/// section for scroll-into-view + highlight (e.g. after a backend validation
/// failure is matched to a section on the add-branch review screen).
enum BranchSummarySection {
  branchInfo,
  contact,
  workingHours,
  coverage,
  services,
  team,
}

/// Normalized data for [BranchSummaryView], shared by the add-branch review
/// screen (draft source) and the branch details screen (saved-branch source).
class BranchSummaryData {
  const BranchSummaryData({
    required this.title,
    required this.badgeLabel,
    required this.badgeType,
    required this.branchTypeLabel,
    required this.phone,
    required this.schedule,
    required this.areaNames,
    required this.serviceNames,
    required this.workerInitials,
    this.caption,
    this.position,
    this.address,
    this.cityName,
    this.managerName,
    this.isCustomSchedule = false,
  });

  final String title;
  final String? caption;
  final String badgeLabel;
  final AppStatusBadgeType badgeType;
  final String branchTypeLabel;
  final LatLng? position;
  final String? address;
  final String? cityName;
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
    this.onEditBranchInfo,
    this.onEditContact,
    this.onEditWorkingHours,
    this.onEditCoverage,
    this.onEditServices,
    this.onEditTeam,
    this.sectionKeys,
    this.highlightedSection,
    super.key,
  });

  static const _visibleServiceCount = 3;
  static const _visibleTeamCount = 4;

  final BranchSummaryData data;
  final VoidCallback? onOpenMaps;
  final VoidCallback? onViewAllServices;
  final VoidCallback? onViewAllWorkers;

  /// When non-null, the corresponding section renders a pencil that invokes
  /// it. Left null (the default) on the add-branch review screen, where
  /// sections must stay read-only/pencil-free.
  final VoidCallback? onEditBranchInfo;
  final VoidCallback? onEditContact;
  final VoidCallback? onEditWorkingHours;
  final VoidCallback? onEditCoverage;
  final VoidCallback? onEditServices;
  final VoidCallback? onEditTeam;

  /// Optional keys, one per section, so a caller can scroll a specific
  /// section into view (e.g. `Scrollable.ensureVisible`) after matching a
  /// backend validation failure to it.
  final Map<BranchSummarySection, GlobalKey>? sectionKeys;

  /// When set, the matching section renders a temporary highlight — used to
  /// draw attention to the section a backend validation error was matched to.
  final BranchSummarySection? highlightedSection;

  Widget _section(BranchSummarySection section, Widget child) {
    Widget result = child;
    if (highlightedSection == section) {
      result = _HighlightedSection(child: result);
    }
    final key = sectionKeys?[section];
    if (key != null) {
      result = KeyedSubtree(key: key, child: result);
    }
    return result;
  }

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
          // Only rendered when an edit callback is supplied — the add-branch
          // review screen now wires this too (see BranchReviewBody), so the
          // section appears there as well as on Branch Details.
          if (onEditBranchInfo != null)
            _section(
              BranchSummarySection.branchInfo,
              _BranchInfoSection(data: data, onEdit: onEditBranchInfo),
            ),
          _section(
            BranchSummarySection.contact,
            _ContactSection(data: data, onEdit: onEditContact),
          ),
          _section(
            BranchSummarySection.workingHours,
            _WorkingHoursSection(data: data, onEdit: onEditWorkingHours),
          ),
          _section(
            BranchSummarySection.coverage,
            _CoverageSection(
              areaNames: data.areaNames,
              onEdit: onEditCoverage,
            ),
          ),
          _section(
            BranchSummarySection.services,
            _ServicesSection(
              serviceNames: data.serviceNames,
              visibleCount: _visibleServiceCount,
              onViewAll: onViewAllServices,
              onEdit: onEditServices,
            ),
          ),
          _section(
            BranchSummarySection.team,
            _TeamSection(
              initials: data.workerInitials,
              visibleCount: _visibleTeamCount,
              onViewAll: onViewAllWorkers,
              onEdit: onEditTeam,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transient tinted/bordered wrapper drawing attention to a section that a
/// backend validation failure was matched to.
class _HighlightedSection extends StatelessWidget {
  const _HighlightedSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.warningContainer,
        border: Border.all(color: colors.warning),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Trailing pencil icon used by section headers that support editing.
/// Mirrors the icon used by `AppSectionHeader` (`shared_ui`) so the visual
/// language matches other section-edit affordances in the app.
Widget _sectionEditIcon(BuildContext context) => AppSvgPicture.asset(
  AppSvgs.branchEdit,
  width: 20,
  height: 20,
  colorFilter: ColorFilter.mode(
    context.appColors.textPrimary,
    BlendMode.srcIn,
  ),
);

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

class _BranchInfoSection extends StatelessWidget {
  const _BranchInfoSection({required this.data, this.onEdit});

  final BranchSummaryData data;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_branch_info'.tr(),
          size: AppSectionSize.compact,
          trailing: onEdit != null
              ? AppSectionTrailing.icon
              : AppSectionTrailing.none,
          trailingIcon: onEdit != null ? _sectionEditIcon(context) : null,
          onTrailingTap: onEdit,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppGroupedKeyValueList(
            items: [
              GroupedKeyValueItem(
                title: 'branches.add_branch.branch_type'.tr(),
                value: data.branchTypeLabel,
              ),
              if (data.cityName != null && data.cityName!.isNotEmpty)
                GroupedKeyValueItem(
                  title: 'branches.add_branch.city'.tr(),
                  value: data.cityName!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.data, this.onEdit});

  final BranchSummaryData data;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_contact'.tr(),
          size: AppSectionSize.compact,
          trailing: onEdit != null
              ? AppSectionTrailing.icon
              : AppSectionTrailing.none,
          trailingIcon: onEdit != null ? _sectionEditIcon(context) : null,
          onTrailingTap: onEdit,
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
  const _WorkingHoursSection({required this.data, this.onEdit});

  final BranchSummaryData data;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final closedLabel = 'branches.details.closed'.tr();
    final byDay = {for (final entry in data.schedule) entry.day: entry};

    final items = [
      for (final day in BranchWeekdays.all)
        _scheduleItem(day, byDay[day], closedLabel, colors.error),
    ];

    final badge = data.isCustomSchedule
        ? AppStatusBadge(
            label: 'branches.details.schedule_custom'.tr(),
            type: AppStatusBadgeType.info,
            size: AppStatusBadgeSize.compact,
          )
        : null;
    final hasTrailing = badge != null || onEdit != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_working_hours'.tr(),
          size: AppSectionSize.compact,
          trailing: hasTrailing
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: hasTrailing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    if (badge != null) badge,
                    if (onEdit != null)
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: _sectionEditIcon(context),
                      ),
                  ],
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
  const _CoverageSection({required this.areaNames, this.onEdit});

  final List<String> areaNames;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_coverage'.tr(),
          size: AppSectionSize.compact,
          trailing: onEdit != null
              ? AppSectionTrailing.icon
              : AppSectionTrailing.none,
          trailingIcon: onEdit != null ? _sectionEditIcon(context) : null,
          onTrailingTap: onEdit,
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
    this.onEdit,
  });

  final List<String> serviceNames;
  final int visibleCount;
  final VoidCallback? onViewAll;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = serviceNames.take(visibleCount).toList();
    final hidden = serviceNames.length - visible.length;
    final viewAll = serviceNames.isEmpty
        ? null
        : _ViewAllLink(
            label: 'branches.review.view_all'.tr(
              namedArgs: {'count': '${serviceNames.length}'},
            ),
            onTap: onViewAll,
          );
    final hasTrailing = viewAll != null || onEdit != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_services'.tr(),
          size: AppSectionSize.compact,
          trailing: hasTrailing
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: hasTrailing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    if (viewAll != null) viewAll,
                    if (onEdit != null)
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: _sectionEditIcon(context),
                      ),
                  ],
                )
              : null,
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
    this.onEdit,
  });

  final List<String> initials;
  final int visibleCount;
  final VoidCallback? onViewAll;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overflow = initials.length - visibleCount;
    final viewAll = initials.isEmpty
        ? null
        : _ViewAllLink(
            label: 'branches.review.workers_count'.tr(
              namedArgs: {'count': '${initials.length}'},
            ),
            onTap: onViewAll,
          );
    final hasTrailing = viewAll != null || onEdit != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'branches.details.section_team'.tr(),
          size: AppSectionSize.compact,
          trailing: hasTrailing
              ? AppSectionTrailing.custom
              : AppSectionTrailing.none,
          trailingWidget: hasTrailing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    if (viewAll != null) viewAll,
                    if (onEdit != null)
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: _sectionEditIcon(context),
                      ),
                  ],
                )
              : null,
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
