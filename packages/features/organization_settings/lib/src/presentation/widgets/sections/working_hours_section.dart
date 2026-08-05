import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One editable day entry for organization working hours.
class WorkingHoursEditEntry {
  const WorkingHoursEditEntry({
    required this.dayId,
    required this.from,
    required this.to,
  });

  /// API weekday code (e.g. `SATURDAY`).
  final String dayId;

  /// Start time in `HH:mm` (24-hour).
  final String from;

  /// End time in `HH:mm` (24-hour).
  final String to;
}

/// One day entry in [WorkingHoursSection].
class WorkingHoursEntry {
  const WorkingHoursEntry({
    required this.dayLabel,
    required this.hoursLabel,
  });

  final String dayLabel;
  final String hoursLabel;
}

/// View-mode working hours section — Figma `3821:18620`.
class WorkingHoursSection extends StatelessWidget {
  const WorkingHoursSection({
    super.key,
    required this.entries,
    this.onEdit,
  });

  final List<WorkingHoursEntry> entries;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_working_hours'.tr(),
      subtitle: 'settings.working_hours_subtitle'.tr(),
      onEdit: onEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.md),
            AppScheduleDayRow(
              title: entries[i].dayLabel,
              value: entries[i].hoursLabel,
            ),
          ],
        ],
      ),
    );
  }
}
