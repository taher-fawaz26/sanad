import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddBranchWizardStepShell extends StatelessWidget {
  const AddBranchWizardStepShell({
    required this.currentStep,
    required this.totalSteps,
    required this.child,
    this.furthestCompletedStep,
    this.onStepTapped,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final int? furthestCompletedStep;
  final ValueChanged<int>? onStepTapped;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (currentStep == 2) {
      return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
        selector: (state) => state.isStepTwoComplete,
        builder: (context, hasCoverage) {
          return _Content(
            currentStep: currentStep,
            totalSteps: totalSteps,
            furthestCompletedStep: furthestCompletedStep,
            onStepTapped: onStepTapped,
            caption: hasCoverage
                ? 'branches.add_branch.coverage_set_title'.tr()
                : 'branches.add_branch.coverage_step_subtitle'.tr(),
            child: child,
          );
        },
      );
    }

    return _Content(
      currentStep: currentStep,
      totalSteps: totalSteps,
      furthestCompletedStep: furthestCompletedStep,
      onStepTapped: onStepTapped,
      caption: switch (currentStep) {
        3 => 'branches.add_branch.services_step_subtitle'.tr(),
        4 => 'branches.add_branch.workers_step_subtitle'.tr(),
        _ => 'branches.add_branch.subtitle'.tr(),
      },
      child: child,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.currentStep,
    required this.totalSteps,
    required this.caption,
    required this.child,
    this.furthestCompletedStep,
    this.onStepTapped,
  });

  final int currentStep;
  final int totalSteps;
  final int? furthestCompletedStep;
  final ValueChanged<int>? onStepTapped;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLargeNavBar(
          title: 'branches.add_branch.title'.tr(),
          caption: caption,
          useLargeTitleStyle: false,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AppWizardStepIndicator(
            currentStep: currentStep,
            totalSteps: totalSteps,
            furthestCompletedStep: furthestCompletedStep,
            onStepTapped: onStepTapped,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
