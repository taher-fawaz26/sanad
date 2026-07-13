import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AddCustomDayResult {
  const AddCustomDayResult({
    required this.day,
    required this.from,
    required this.to,
  });

  final String day;
  final String from;
  final String to;
}

/// Figma `Views / Bottom Sheets` — Add custom day (`287:7918`).
Future<AddCustomDayResult?> showAddCustomDayBottomSheet({
  required BuildContext context,
  required List<String> availableDays,
}) {
  return showAppBottomSheet<AddCustomDayResult>(
    context: context,
    title: 'branches.add_branch.add_custom_day_title'.tr(),
    child: _AddCustomDaySheetBody(availableDays: availableDays),
  );
}

class _AddCustomDaySheetBody extends StatefulWidget {
  const _AddCustomDaySheetBody({required this.availableDays});

  final List<String> availableDays;

  @override
  State<_AddCustomDaySheetBody> createState() => _AddCustomDaySheetBodyState();
}

class _AddCustomDaySheetBodyState extends State<_AddCustomDaySheetBody> {
  late String _selectedDay;
  TimeOfDay _fromTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 14, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.availableDays.first;
  }

  bool get _isValid {
    final fromMinutes = _fromTime.hour * 60 + _fromTime.minute;
    final toMinutes = _toTime.hour * 60 + _toTime.minute;
    return toMinutes > fromMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelectField(
          label: 'branches.add_branch.day_label'.tr(),
          value: BranchScheduleFormatter.localizedDay(_selectedDay),
          onTap: _pickDay,
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppSelectField(
                label: 'branches.add_branch.from_label'.tr(),
                value: BranchScheduleFormatter.formatTime(
                  BranchScheduleFormatter.toApiTime(_fromTime),
                ),
                showChevron: false,
                onTap: () => _pickTime(isFrom: true),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppSelectField(
                label: 'branches.add_branch.to_label'.tr(),
                value: BranchScheduleFormatter.formatTime(
                  BranchScheduleFormatter.toApiTime(_toTime),
                ),
                showChevron: false,
                onTap: () => _pickTime(isFrom: false),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'branches.add_branch.add_day_button'.tr(),
          onPressed: _isValid ? _submit : null,
        ),
      ],
    );
  }

  Future<void> _pickDay() async {
    await showAppActionSheet(
      context: context,
      title: 'branches.add_branch.day_label'.tr(),
      cancelLabel: 'branches.add_branch.cancel'.tr(),
      items: widget.availableDays
          .map(
            (day) => AppActionSheetItem(
              label: BranchScheduleFormatter.localizedDay(day),
              onTap: () => setState(() => _selectedDay = day),
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: context.appColors.primary,
              onPrimary: context.appColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromTime = picked;
      } else {
        _toTime = picked;
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      AddCustomDayResult(
        day: _selectedDay,
        from: BranchScheduleFormatter.toApiTime(_fromTime),
        to: BranchScheduleFormatter.toApiTime(_toTime),
      ),
    );
  }
}
