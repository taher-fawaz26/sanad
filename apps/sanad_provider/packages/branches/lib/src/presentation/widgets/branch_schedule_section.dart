import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Working-hours section — company read-only list or editable custom
/// schedule.
///
/// Multi-slot days render via the shared [AppWeeklyScheduleDayCard] (one
/// container per day holding every slot) instead of a single truncating
/// row. Adding a slot for a day that already has one or more slots merges
/// into that day's existing group through [onAddSlot]
/// (`BranchSchedulePolicy.upsertSlot` — the same shared policy
/// organization_settings' working-hours edit sheet uses) — the day picker
/// never excludes an already-used day.
class BranchScheduleSection extends StatelessWidget {
  const BranchScheduleSection({
    required this.mode,
    required this.companySchedule,
    required this.customSchedule,
    required this.onModeChanged,
    required this.onAddSlot,
    required this.onRemoveSlot,
    this.rejection,
    super.key,
  });

  final BranchScheduleMode mode;
  final List<BranchAvailabilityEntity> companySchedule;
  final List<BranchAvailabilityEntity> customSchedule;
  final ValueChanged<BranchScheduleMode> onModeChanged;

  /// Attempts to add a `[from, to)` slot to `dayId`'s custom schedule (see
  /// [BranchSchedulePolicy.upsertSlot]). The caller owns the actual
  /// persistence/state change; this widget only triggers the attempt and
  /// renders [rejection] when it fails.
  final SlotValidation Function(String dayId, String from, String to) onAddSlot;

  /// Deletes exactly one slot — `dayId`'s slot at its own chronological
  /// `slotIndex` — never the whole day unless it was the last slot.
  final void Function(String dayId, int slotIndex) onRemoveSlot;

  /// Most recent add-slot rejection, if any — renders an inline localized
  /// error below the "Add a day" button (mirrors organization_settings'
  /// working-hours rejection banner, including its i18n keys).
  final ScheduleSlotRejection? rejection;

  @override
  Widget build(BuildContext context) {
    final schedule = mode == BranchScheduleMode.company
        ? companySchedule
        : customSchedule;
    final localeName = context.locale.toString();

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
          for (final entry in schedule)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppWeeklyScheduleDayCard(
                group: AppWeeklyScheduleDayGroup(
                  dayLabel: BranchScheduleFormatter.localizedDay(entry.day),
                  slots: [
                    for (final (index, slot) in entry.slots.indexed)
                      AppWeeklyScheduleSlotRow(
                        hoursLabel: BranchScheduleFormatter.formatSlot(
                          slot,
                          locale: localeName,
                        ),
                        onDelete: mode == BranchScheduleMode.custom
                            ? () => onRemoveSlot(entry.day, index)
                            : null,
                        deleteSemanticLabel: 'common.delete'.tr(),
                      ),
                  ],
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
          if (rejection != null) ...[
            SizedBox(height: AppSpacing.xs),
            _RejectionText(rejection: rejection!, locale: localeName),
          ],
        ],
      ],
    );
  }

  Future<void> _openAddDaySheet(BuildContext context) async {
    // Every weekday stays selectable — adding a slot for a day that
    // already has one or more slots is a merge (onAddSlot upserts into
    // that day's existing group via BranchSchedulePolicy), not a duplicate
    // day entry.
    final result = await SheetNavigator.push<AppAddScheduleDayResult>(
      context,
      AppAddScheduleDaySheet(
        days: BranchWeekdays.all
            .map(
              (day) => AppScheduleDayOption(
                id: day,
                label: BranchScheduleFormatter.localizedDay(day),
              ),
            )
            .toList(),
        dayLabel: 'branches.add_branch.day_label'.tr(),
        fromLabel: 'branches.add_branch.from_label'.tr(),
        toLabel: 'branches.add_branch.to_label'.tr(),
        confirmLabel: 'branches.add_branch.add_day_button'.tr(),
        cancelLabel: 'common.cancel'.tr(),
        onPickDay: (context, days, selected, onDaySelected) {
          SheetNavigator.push<void>(
            context,
            AppActionList(
              items: days
                  .map(
                    (day) => AppActionSheetItem(
                      label: day.label,
                      onTap: () => onDaySelected(day),
                    ),
                  )
                  .toList(),
            ),
            settings: SheetRouteSettings(
              title: 'branches.add_branch.day_label'.tr(),
              padChild: false,
            ),
          );
        },
      ),
      settings: SheetRouteSettings(
        title: 'branches.add_branch.add_custom_day_title'.tr(),
      ),
    );

    if (result == null) return;
    // Consults BranchSchedulePolicy — the same source of truth used at
    // save time — and immediately merges/re-sorts the schedule. On
    // rejection nothing changes here; the caller stashes [rejection] so it
    // renders below the "Add a day" button.
    onAddSlot(result.day, result.from, result.to);
  }
}

/// Localized inline error for a rejected add-slot attempt — reuses
/// organization_settings' exact working-hours rejection copy (same i18n
/// keys) so both flows show byte-identical messaging.
class _RejectionText extends StatelessWidget {
  const _RejectionText({required this.rejection, required this.locale});

  final ScheduleSlotRejection rejection;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return Text(
      _message(),
      style: typography.smallNormal.copyWith(color: colors.error),
      textAlign: TextAlign.start,
    );
  }

  String _message() {
    switch (rejection.reason) {
      case SlotValidationReason.overlapsExisting:
        final conflict = rejection.conflict;
        if (conflict == null) {
          return 'settings.working_hours_invalid_times_error'.tr();
        }
        return 'settings.working_hours_overlap_error'.tr(
          namedArgs: {
            'day': BranchScheduleFormatter.localizedDay(rejection.dayId),
            'from': BranchScheduleFormatter.formatTime(
              conflict.from,
              locale: locale,
            ),
            'to': BranchScheduleFormatter.formatTime(
              conflict.to,
              locale: locale,
            ),
          },
        );
      case SlotValidationReason.endBeforeOrEqualStart:
      case SlotValidationReason.malformed:
        return 'settings.working_hours_invalid_times_error'.tr();
      case SlotValidationReason.valid:
        return '';
    }
  }
}
