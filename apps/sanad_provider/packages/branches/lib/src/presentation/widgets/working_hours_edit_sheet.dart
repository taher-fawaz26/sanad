import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Result of a confirmed [WorkingHoursEditSheet] submission.
class WorkingHoursEditResult {
  const WorkingHoursEditResult({
    required this.availabilityMode,
    required this.availability,
  });

  final BranchAvailabilityMode availabilityMode;

  /// Resolved schedule to submit — company hours when [availabilityMode] is
  /// [BranchAvailabilityMode.coreHours], the custom schedule otherwise.
  final List<BranchAvailabilityEntity> availability;
}

/// Opens the Working Hours section editor. Pops `null` when dismissed
/// without saving, otherwise a [WorkingHoursEditResult] with the confirmed
/// schedule.
///
/// [companySchedule] must be fetched by the caller *before* opening this
/// sheet (see `GetCompanyScheduleUseCase`) — the sheet renders fully-formed
/// content from its very first frame rather than fetching internally and
/// swapping a loading state in, which caused the sheet's auto-sized height
/// (`SheetSize.content`) to change immediately after mount.
Future<WorkingHoursEditResult?> showWorkingHoursEditSheet({
  required BuildContext context,
  required BranchAvailabilityMode initialMode,
  required List<BranchAvailabilityEntity> initialCustomSchedule,
  required List<BranchAvailabilityEntity> companySchedule,
}) {
  return SheetNavigator.push<WorkingHoursEditResult>(
    context,
    WorkingHoursEditSheet(
      initialMode: initialMode,
      initialCustomSchedule: initialCustomSchedule,
      companySchedule: companySchedule,
    ),
    settings: SheetRouteSettings(
      title: 'branches.details.section_working_hours'.tr(),
    ),
  );
}

/// Working Hours section editor — company vs custom schedule. Shell-agnostic;
/// pair with [SheetNavigator] (see [showWorkingHoursEditSheet]).
class WorkingHoursEditSheet extends StatefulWidget {
  const WorkingHoursEditSheet({
    required this.initialMode,
    required this.initialCustomSchedule,
    required this.companySchedule,
    super.key,
  });

  final BranchAvailabilityMode initialMode;
  final List<BranchAvailabilityEntity> initialCustomSchedule;
  final List<BranchAvailabilityEntity> companySchedule;

  @override
  State<WorkingHoursEditSheet> createState() => _WorkingHoursEditSheetState();
}

class _WorkingHoursEditSheetState extends State<WorkingHoursEditSheet> {
  late BranchScheduleMode _mode;
  late List<BranchAvailabilityEntity> _customSchedule;

  /// Most recent add-slot rejection — mirrors `AddBranchDraftCubit`'s
  /// `lastScheduleRejection`, kept as local widget state here since this
  /// sheet owns its own schedule draft rather than a cubit.
  ScheduleSlotRejection? _rejection;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == BranchAvailabilityMode.custom
        ? BranchScheduleMode.custom
        : BranchScheduleMode.company;
    _customSchedule = List.of(widget.initialCustomSchedule);
    if (_mode == BranchScheduleMode.custom && _customSchedule.isEmpty) {
      _customSchedule = List.of(widget.companySchedule);
    }
  }

  void _onModeChanged(BranchScheduleMode mode) {
    setState(() {
      _mode = mode;
      _rejection = null;
      if (mode == BranchScheduleMode.custom && _customSchedule.isEmpty) {
        _customSchedule = List.of(widget.companySchedule);
      }
    });
  }

  /// Delegates to the same shared [BranchSchedulePolicy] the Add Branch
  /// wizard's schedule step uses, so the two flows can never re-diverge on
  /// scheduling behavior.
  SlotValidation _onAddSlot(String dayId, String from, String to) {
    final result = BranchSchedulePolicy.upsertSlot(
      days: _customSchedule,
      dayId: dayId,
      from: from,
      to: to,
    );
    if (!result.validation.isValid) {
      setState(
        () => _rejection = ScheduleSlotRejection(
          reason: result.validation.reason,
          dayId: dayId,
          from: from,
          to: to,
          conflict: result.validation.conflict,
        ),
      );
      return result.validation;
    }
    setState(() {
      _customSchedule = result.days;
      _rejection = null;
    });
    return result.validation;
  }

  void _onRemoveSlot(String dayId, int slotIndex) {
    setState(() {
      _customSchedule = BranchSchedulePolicy.removeSlot(
        days: _customSchedule,
        dayId: dayId,
        slotIndex: slotIndex,
      );
      _rejection = null;
    });
  }

  bool get _isValid =>
      _mode == BranchScheduleMode.company || _customSchedule.isNotEmpty;

  bool get _hasChanges {
    final initialMode = widget.initialMode == BranchAvailabilityMode.custom
        ? BranchScheduleMode.custom
        : BranchScheduleMode.company;
    if (_mode != initialMode) return true;
    if (_mode == BranchScheduleMode.company) return false;
    return !_scheduleEquals(_customSchedule, widget.initialCustomSchedule);
  }

  bool _scheduleEquals(
    List<BranchAvailabilityEntity> a,
    List<BranchAvailabilityEntity> b,
  ) {
    if (a.length != b.length) return false;
    final byDayA = {for (final entry in a) entry.day: entry};
    final byDayB = {for (final entry in b) entry.day: entry};
    if (byDayA.keys.toSet().difference(byDayB.keys.toSet()).isNotEmpty) {
      return false;
    }
    for (final day in byDayA.keys) {
      if (byDayA[day] != byDayB[day]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BranchScheduleSection(
          mode: _mode,
          companySchedule: widget.companySchedule,
          customSchedule: _customSchedule,
          rejection: _rejection,
          onModeChanged: _onModeChanged,
          onAddSlot: _onAddSlot,
          onRemoveSlot: _onRemoveSlot,
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'branches.edit_branch.save_button'.tr(),
          onPressed: _isValid && _hasChanges ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    final isCustom = _mode == BranchScheduleMode.custom;
    Navigator.of(context).pop(
      WorkingHoursEditResult(
        availabilityMode: isCustom
            ? BranchAvailabilityMode.custom
            : BranchAvailabilityMode.coreHours,
        availability: isCustom ? _customSchedule : widget.companySchedule,
      ),
    );
  }
}
