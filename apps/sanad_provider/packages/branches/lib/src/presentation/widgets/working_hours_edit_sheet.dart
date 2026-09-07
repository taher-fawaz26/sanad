import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/presentation/bloc/branch_schedule_editor/branch_schedule_editor_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
/// sheet (`BranchDetailsBloc` pre-fetches it into state, SAN-780) — the
/// sheet renders fully-formed content from its very first frame.
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
///
/// Draft state (mode / custom slots / rejection) is owned by
/// [BranchScheduleEditorBloc]. The widget is stateless and dispatches events
/// through the bloc; the shared [BranchSchedulePolicy] backs both this sheet
/// and the Add Branch wizard's schedule step so they can never diverge.
class WorkingHoursEditSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider<BranchScheduleEditorBloc>(
      create: (_) => BranchScheduleEditorBloc(
        initialMode: initialMode,
        initialCustomSchedule: initialCustomSchedule,
        companySchedule: companySchedule,
      ),
      child: const _WorkingHoursEditBody(),
    );
  }
}

class _WorkingHoursEditBody extends StatelessWidget {
  const _WorkingHoursEditBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchScheduleEditorBloc, BranchScheduleEditorState>(
      builder: (context, state) {
        final bloc = context.read<BranchScheduleEditorBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BranchScheduleSection(
              mode: state.mode,
              companySchedule: state.companySchedule,
              customSchedule: state.customSchedule,
              rejection: state.rejection,
              onModeChanged: (mode) =>
                  bloc.add(BranchScheduleModeChanged(mode)),
              onAddSlot: (dayId, from, to) =>
                  bloc.tryAddSlot(dayId: dayId, from: from, to: to),
              onRemoveSlot: (dayId, slotIndex) => bloc.add(
                BranchScheduleSlotRemoved(dayId: dayId, slotIndex: slotIndex),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'branches.edit_branch.save_button'.tr(),
              onPressed: state.canSubmit
                  ? () => Navigator.of(context).pop(
                      WorkingHoursEditResult(
                        availabilityMode: state.resolvedAvailabilityMode,
                        availability: state.resolvedAvailability,
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }
}
