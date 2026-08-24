import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// One rendered time slot within a [WorkingHoursDayGroup].
///
/// Type alias over the generic `shared_ui` widget — the day-container shell
/// is shared with the per-branch working-hours flow (`branches` package),
/// so both present the exact same visual/behavioral primitives.
typedef WorkingHoursSlotRow = AppWeeklyScheduleSlotRow;

/// One day rendered by [WorkingHoursDayCard] — the grouping unit shared by
/// the view-mode section and the edit sheet, so both render the exact same
/// "one container per day" shell.
typedef WorkingHoursDayGroup = AppWeeklyScheduleDayGroup;

/// The single "day container" building block reused by both the view-mode
/// [WorkingHoursSection] and the edit sheet
/// (`edit_working_hours_bottom_sheet.dart`).
typedef WorkingHoursDayCard = AppWeeklyScheduleDayCard;

/// View-mode working hours section — Figma `3821:18620`.
class WorkingHoursSection extends StatelessWidget {
  const WorkingHoursSection({
    required this.groups,
    super.key,
    this.onEdit,
  });

  /// One entry per weekday to render, already ordered
  /// (`WorkingHoursPolicy.sortDaysCanonically`, Saturday → Friday).
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
                  WorkingHoursDayCard(group: groups[i]),
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
