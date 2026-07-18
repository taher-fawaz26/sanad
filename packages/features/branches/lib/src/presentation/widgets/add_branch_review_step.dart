import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/branch_maps_launcher.dart';
import 'package:branches/src/presentation/widgets/add_branch_wizard_step_shell.dart';
import 'package:branches/src/presentation/widgets/branch_summary_content.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Figma add-branch review screen (`365:14892`).
class AddBranchReviewStep extends StatelessWidget {
  const AddBranchReviewStep({
    required this.currentStep,
    required this.totalSteps,
    required this.furthestCompletedStep,
    required this.onStepTapped,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final int furthestCompletedStep;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    return AddBranchWizardStepShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      furthestCompletedStep: furthestCompletedStep,
      onStepTapped: onStepTapped,
      child: BlocBuilder<AddBranchDraftCubit, AddBranchDraft>(
        builder: (context, draft) {
          return BlocSelector<AddBranchBloc, AddBranchState,
              List<BranchAvailabilityEntity>>(
            selector: (state) => state.companySchedule,
            builder: (context, companySchedule) {
              final model = BranchSummaryViewModel.fromDraft(
                draft: draft,
                companySchedule: companySchedule,
                headerTitle: 'branches.add_branch.review_title'.tr(),
                headerCaption: 'branches.add_branch.review_subtitle'.tr(),
                onOpenMaps: () => _openMaps(context, draft),
              );

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: BranchSummaryContent(model: model),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openMaps(BuildContext context, AddBranchDraft draft) async {
    if (draft.pickedPosition == null) return;
    final opened = await BranchMapsLauncher.openCoordinates(
      lat: draft.pickedPosition!.latitude,
      lng: draft.pickedPosition!.longitude,
      label: draft.branchAddress,
    );
    if (!context.mounted || opened) return;
    showAppSnackbar(
      context: context,
      title: 'branches.details.maps_unavailable'.tr(),
    );
  }
}
