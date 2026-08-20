import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// One editable day entry for organization working hours.
class WorkingHoursEditEntry {
  const WorkingHoursEditEntry({
    required this.dayId,
    required this.from,
    required this.to,
  });

  /// Exact backend weekday value (e.g. `Saturday`) — see
  /// `WorkingHoursDayIds` in the domain layer.
  final String dayId;

  /// Start time in `HH:mm` (24-hour).
  final String from;

  /// End time in `HH:mm` (24-hour).
  final String to;
}

/// One rendered time slot within a [WorkingHoursDayGroup].
class WorkingHoursSlotView {
  const WorkingHoursSlotView({required this.hoursLabel});

  /// Fully-formatted, locale-aware label — e.g. `9:00 AM – 3:00 PM` /
  /// `9:00 ص – 3:00 م`.
  final String hoursLabel;
}

/// One day rendered by [WorkingHoursSection] — the grouping unit.
///
/// The section renders exactly one card per group; multi-slot groups get
/// an expand/collapse affordance (Flutter's [ExpansionTile]).
class WorkingHoursDayGroup {
  const WorkingHoursDayGroup({
    required this.dayLabel,
    required this.slots,
  });

  /// Localized weekday label (e.g. `Saturday` / `السبت`).
  final String dayLabel;

  /// Slots in chronological order (`WorkingHoursPolicy.sortSlotsChronologically`).
  /// Never empty by convention — a day with zero slots is not emitted.
  final List<WorkingHoursSlotView> slots;
}

/// View-mode working hours section — Figma `3821:18620`.
///
/// One card per weekday, each carrying that day's chronologically-sorted
/// slots. Multi-slot days render inside an [ExpansionTile] (initially
/// expanded) so long weeks stay scan-able. Single-slot days show their
/// row inline with no chevron.
class WorkingHoursSection extends StatelessWidget {
  const WorkingHoursSection({
    required this.groups,
    super.key,
    this.onEdit,
  });

  /// One entry per weekday to render. The list order is preserved — pass
  /// days in the intended visual order (Saturday → Friday, sorted via
  /// `WorkingHoursPolicy.sortDaysCanonically` at the mapper).
  final List<WorkingHoursDayGroup> groups;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_working_hours'.tr(),
      subtitle: 'settings.working_hours_subtitle'.tr(),
      onEdit: onEdit,
      child: groups.isEmpty
          ? _EmptyState()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0) SizedBox(height: AppSpacing.md),
                  _WorkingHoursDayCard(group: groups[i]),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return Text(
      'settings.working_hours_no_hours_configured'.tr(),
      style: typography.smallNormal.copyWith(color: colors.textSecondary),
    );
  }
}

/// One weekday's card. Single-slot days render as an inline row; multi-slot
/// days wrap the slot rows in an [ExpansionTile] that starts expanded.
class _WorkingHoursDayCard extends StatelessWidget {
  const _WorkingHoursDayCard({required this.group});

  final WorkingHoursDayGroup group;

  @override
  Widget build(BuildContext context) {
    if (group.slots.length <= 1) {
      final hours = group.slots.isEmpty ? '' : group.slots.first.hoursLabel;
      return AppScheduleDayRow(title: group.dayLabel, value: hours);
    }
    return _MultiSlotDayCard(group: group);
  }
}

class _MultiSlotDayCard extends StatelessWidget {
  const _MultiSlotDayCard({required this.group});

  final WorkingHoursDayGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusLg),
      ),
      // Suppress the divider ExpansionTile paints above/below itself when
      // wrapped in a DecoratedBox — the outer border is already the visual
      // boundary. `iconColor`/`collapsedIconColor` pick up design-system
      // tokens rather than the Material default.
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: const ListTileThemeData(
            visualDensity: VisualDensity.compact,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          iconColor: colors.textSecondary,
          collapsedIconColor: colors.textSecondary,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            group.dayLabel,
            style: typography.semiBold(typography.regularNormal),
          ),
          children: [
            for (var i = 0; i < group.slots.length; i++) ...[
              if (i > 0) SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  group.slots[i].hoursLabel,
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
