import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add branch — pre-submit review summary of the draft.
///
/// Figma `review` (`365:14892`). Renders the draft through the shared
/// [BranchSummaryView] so it stays visually identical to branch details.
class BranchReviewBody extends StatelessWidget {
  const BranchReviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddBranchDraftCubit, AddBranchDraft>(
      builder: (context, draft) {
        final companySchedule = context
            .watch<AddBranchBloc>()
            .state
            .companySchedule;
        final schedule = draft.scheduleMode == BranchScheduleMode.company
            ? companySchedule
            : draft.customSchedule;

        final position = draft.pickedPosition;

        return BranchSummaryView(
          data: BranchSummaryData(
            title: 'branches.company_name'.tr(),
            caption: _branchTypeLabel(draft.branchType),
            badgeLabel: 'branches.status_active'.tr(),
            badgeType: AppStatusBadgeType.success,
            position: position,
            address: draft.branchAddress,
            phone: draft.phone,
            managerName: draft.selectedManager?.fullName,
            isCustomSchedule: draft.scheduleMode == BranchScheduleMode.custom,
            schedule: schedule,
            areaNames: [for (final area in draft.servingAreas) area.name],
            serviceNames: [
              for (final service in draft.selectedServices) service.name,
            ],
            workerInitials: [
              for (final worker in draft.selectedWorkers) worker.initials,
            ],
          ),
          onOpenMaps: position == null
              ? null
              : () => _openMaps(context, position.latitude, position.longitude),
        );
      },
    );
  }

  Future<void> _openMaps(BuildContext context, double lat, double lng) async {
    final opened = await BranchMapsLauncher.openCoordinates(lat, lng);
    if (!context.mounted || opened) return;
    showAppSnackbar(
      context: context,
      title: 'branches.details.maps_unavailable'.tr(),
    );
  }
}

String _branchTypeLabel(BranchType type) => switch (type) {
  BranchType.mainBranch => 'branches.add_branch.branch_type_main_branch'.tr(),
  BranchType.headquarters =>
    'branches.add_branch.branch_type_headquarters'.tr(),
  BranchType.mainStore => 'branches.add_branch.branch_type_main_store'.tr(),
  BranchType.warehouse => 'branches.add_branch.branch_type_warehouse'.tr(),
};
