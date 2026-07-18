import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddBranchWizardFooter extends StatelessWidget {
  const AddBranchWizardFooter({
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSubmit,
    required this.onAddCoverage,
    required this.onAddServices,
    required this.onAddWorkers,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onAddCoverage;
  final VoidCallback onAddServices;
  final VoidCallback onAddWorkers;

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      child: switch (currentStep) {
        1 => _StepOneButton(onNext: onNext),
        2 => _StepTwoButton(
          onNext: onNext,
          onAddCoverage: onAddCoverage,
        ),
        3 => _StepThreeButton(
          onNext: onNext,
          onAddServices: onAddServices,
        ),
        4 => _StepFourButton(
          onNext: onNext,
          onAddWorkers: onAddWorkers,
        ),
        5 => _ReviewSubmitButton(onSubmit: onSubmit),
        _ => _ReviewSubmitButton(onSubmit: onSubmit),
      },
    );
  }
}

class _StepOneButton extends StatelessWidget {
  const _StepOneButton({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
      selector: (state) => state.isStepOneComplete,
      builder: (context, canProceed) {
        return BlocSelector<
          AddBranchBloc,
          AddBranchState,
          ({bool isLoading, bool isLoadingSetup})
        >(
          selector: (state) => (
            isLoading: state.isLoading,
            isLoadingSetup: state.isLoadingSetup,
          ),
          builder: (context, rec) {
            final disabled = rec.isLoadingSetup || !canProceed;
            return AppButton(
              label: 'branches.add_branch.next_button'.tr(),
              isLoading: rec.isLoading,
              onPressed: rec.isLoading || disabled ? null : onNext,
            );
          },
        );
      },
    );
  }
}

class _StepTwoButton extends StatelessWidget {
  const _StepTwoButton({
    required this.onNext,
    required this.onAddCoverage,
  });

  final VoidCallback onNext;
  final VoidCallback onAddCoverage;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
      selector: (state) => state.isStepTwoComplete,
      builder: (context, hasCoverage) {
        if (!hasCoverage) {
          return AppButton(
            label: 'branches.add_branch.add_location_button'.tr(),
            onPressed: onAddCoverage,
          );
        }
        return AppButton(
          label: 'branches.add_branch.next_button'.tr(),
          onPressed: onNext,
        );
      },
    );
  }
}

class _StepThreeButton extends StatelessWidget {
  const _StepThreeButton({
    required this.onNext,
    required this.onAddServices,
  });

  final VoidCallback onNext;
  final VoidCallback onAddServices;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
      selector: (state) => state.isStepThreeComplete,
      builder: (context, hasServices) {
        if (!hasServices) {
          return AppButton(
            label: 'branches.add_branch.add_services_button'.tr(),
            onPressed: onAddServices,
          );
        }
        return AppButton(
          label: 'branches.add_branch.next_button'.tr(),
          onPressed: onNext,
        );
      },
    );
  }
}

class _StepFourButton extends StatelessWidget {
  const _StepFourButton({
    required this.onNext,
    required this.onAddWorkers,
  });

  final VoidCallback onNext;
  final VoidCallback onAddWorkers;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
      selector: (state) => state.isStepFourComplete,
      builder: (context, hasWorkers) {
        if (!hasWorkers) {
          return AppButton(
            label: 'branches.add_branch.add_workers_button'.tr(),
            onPressed: onAddWorkers,
          );
        }
        return AppButton(
          label: 'branches.add_branch.review_button'.tr(),
          onPressed: onNext,
        );
      },
    );
  }
}

class _ReviewSubmitButton extends StatelessWidget {
  const _ReviewSubmitButton({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchBloc, AddBranchState, bool>(
      selector: (state) => state.isLoading,
      builder: (context, isLoading) {
        return AppButton(
          label: 'branches.add_branch.submit_button'.tr(),
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        );
      },
    );
  }
}
