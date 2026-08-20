import 'package:app_assets/app_assets.dart';
import 'package:branches/branches.dart'
    show BranchScheduleFormatter, BranchTimeSlotEntity;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the working hours edit bottom sheet — Figma `3821:18452`.
///
/// Returns the updated schedule when the user taps Save, or `null` when
/// dismissed without saving.
Future<List<WorkingHoursEditEntry>?> showEditWorkingHoursBottomSheet({
  required BuildContext context,
  List<WorkingHoursEditEntry> initialEntries = const [],
}) {
  return SheetNavigator.push<List<WorkingHoursEditEntry>>(
    context,
    _EditWorkingHoursSheetBody(initialEntries: initialEntries),
  );
}

class _EditWorkingHoursSheetBody extends StatefulWidget {
  const _EditWorkingHoursSheetBody({required this.initialEntries});

  final List<WorkingHoursEditEntry> initialEntries;

  @override
  State<_EditWorkingHoursSheetBody> createState() =>
      _EditWorkingHoursSheetBodyState();
}

class _EditWorkingHoursSheetBodyState
    extends State<_EditWorkingHoursSheetBody> {
  late List<WorkingHoursEditEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<WorkingHoursEditEntry>.from(widget.initialEntries);
  }

  void _deleteEntryAt(int index) {
    // Delete by row index — a day can now have multiple slots (SAN-568),
    // so filtering by dayId would nuke every split-shift for that day.
    setState(() {
      _entries = [..._entries]..removeAt(index);
    });
  }

  void _save() =>
      Navigator.of(context).pop(List<WorkingHoursEditEntry>.from(_entries));

  Future<void> _openAddDaySheet() async {
    // Do NOT filter out days that already have a slot — users need to be
    // able to add split shifts on the same day (SAN-568). Multiple entries
    // per day are collapsed back into WorkingHoursDayEntity.slots on save.
    final result = await SheetNavigator.push<AppAddScheduleDayResult>(
      context,
      AppAddScheduleDaySheet(
        days: WorkingHoursDayIds.all
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

    if (result == null || !mounted) return;

    setState(() {
      _entries = [
        ..._entries,
        WorkingHoursEditEntry(
          dayId: result.day,
          from: result.from,
          to: result.to,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: 'settings.section_working_hours'.tr()),
          SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: ShapeDecoration(
              color: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                for (final (index, entry) in _entries.indexed)
                  AppScheduleDayRow(
                    title: BranchScheduleFormatter.localizedDay(entry.dayId),
                    value: BranchScheduleFormatter.formatSlot(
                      BranchTimeSlotEntity(
                        from: entry.from,
                        to: entry.to,
                      ),
                    ),
                    onDelete: () => _deleteEntryAt(index),
                  ),
                AppButtonPresets.outline(
                  label: 'settings.add_day'.tr(),
                  size: AppButtonSize.block,
                  icon: const Icon(Icons.add),
                  iconPosition: AppButtonIconPosition.center,
                  onPressed: _openAddDaySheet,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'common.save'.tr(),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.tools,
          width: AppDimension.iconMenu,
          height: AppDimension.iconMenu,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
