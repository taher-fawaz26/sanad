import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_section_card.dart';

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
    return SettingsSectionCard(
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
