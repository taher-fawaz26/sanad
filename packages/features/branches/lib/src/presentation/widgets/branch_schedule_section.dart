import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:branches/src/presentation/widgets/add_custom_day_bottom_sheet.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_day_row.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum BranchScheduleMode { company, custom }

/// Working-hours section — company read-only list or editable custom schedule.
class BranchScheduleSection extends StatelessWidget {
  const BranchScheduleSection({
    required this.mode,
    required this.companySchedule,
    required this.customSchedule,
    required this.onModeChanged,
    required this.onCustomScheduleChanged,
    super.key,
  });

  final BranchScheduleMode mode;
  final List<BranchAvailabilityEntity> companySchedule;
  final List<BranchAvailabilityEntity> customSchedule;
  final ValueChanged<BranchScheduleMode> onModeChanged;
  final ValueChanged<List<BranchAvailabilityEntity>> onCustomScheduleChanged;

  @override
  Widget build(BuildContext context) {
    final schedule = mode == BranchScheduleMode.company
        ? companySchedule
        : customSchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppRadioGroup<BranchScheduleMode>(
          value: mode,
          onChanged: (value) {
            if (value != null) onModeChanged(value);
          },
          options: [
            AppRadioOption(
              value: BranchScheduleMode.company,
              label: 'branches.add_branch.use_company_schedule'.tr(),
            ),
            AppRadioOption(
              value: BranchScheduleMode.custom,
              label: 'branches.add_branch.set_custom_schedule'.tr(),
            ),
          ],
        ),
        if (schedule.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          ...schedule.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: BranchScheduleDayRow(
                availability: entry,
                onDelete: mode == BranchScheduleMode.custom
                    ? () => _deleteDay(entry.day)
                    : null,
              ),
            ),
          ),
        ],
        if (mode == BranchScheduleMode.custom) ...[
          SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButtonPresets.outline(
              label: 'branches.add_branch.add_custom_day'.tr(),
              size: AppButtonSize.large,
              icon: const Icon(Icons.add),
              iconPosition: AppButtonIconPosition.center,
              onPressed: () => _openAddDaySheet(context),
            ),
          ),
        ],
      ],
    );
  }

  void _deleteDay(String day) {
    onCustomScheduleChanged(
      customSchedule.where((entry) => entry.day != day).toList(),
    );
  }

  Future<void> _openAddDaySheet(BuildContext context) async {
    final existingDays = customSchedule.map((entry) => entry.day).toSet();
    final availableDays = BranchWeekdays.all
        .where((day) => !existingDays.contains(day))
        .toList();

    if (availableDays.isEmpty) {
      showAppSnackbar(
        context: context,
        title: 'branches.add_branch.all_days_added'.tr(),
      );
      return;
    }

    final result = await showAddCustomDayBottomSheet(
      context: context,
      availableDays: availableDays,
    );

    if (result == null) return;

    onCustomScheduleChanged([
      ...customSchedule,
      BranchAvailabilityEntity(
        day: result.day,
        slots: [
          BranchTimeSlotEntity(from: result.from, to: result.to),
        ],
      ),
    ]);
  }
}
