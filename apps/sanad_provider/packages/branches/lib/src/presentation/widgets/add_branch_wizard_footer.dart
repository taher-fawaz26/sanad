import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddBranchWizardFooter extends StatelessWidget {
  const AddBranchWizardFooter({
    required this.currentStep,
    required this.onNext,
    required this.onSubmit,
    required this.onAddCoverage,
    required this.onAddServices,
    required this.onAddWorkers,
    this.isEdit = false,
    this.coverageAccessDenied = false,
    this.onOpenLocationSettings,
    super.key,
  });

  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onAddCoverage;
  final VoidCallback onAddServices;
  final VoidCallback onAddWorkers;

  /// Edit mode: show a Save button on every step (the whole draft is submitted
  /// as one PATCH from anywhere) instead of the create flow's per-step buttons.
  final bool isEdit;
  final bool coverageAccessDenied;
  final VoidCallback? onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: isEdit
          ? _EditSaveButton(onSave: onSubmit)
          : switch (currentStep) {
              1 => _StepOneButton(onNext: onNext),
              2 when coverageAccessDenied => AppButton(
                label: 'common.open_settings'.tr(),
                onPressed: onOpenLocationSettings,
              ),
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
              _ => _SubmitButton(onSubmit: onSubmit),
            },
    );
  }
}

/// Edit-mode footer: Save on every step, enabled only when the whole draft is
/// valid (all steps complete + phone is either empty or a valid format),
/// disabled while a save is in flight.
class _EditSaveButton extends StatelessWidget {
  const _EditSaveButton({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchDraftCubit, AddBranchDraft, bool>(
      selector: (state) {
        final phone = state.phone.trim();
        final phoneValid = phone.isEmpty || UaePhoneValidator.isValid(phone);
        return state.canSubmit && phoneValid;
      },
      builder: (context, canSave) {
        return BlocSelector<AddBranchBloc, AddBranchState, bool>(
          selector: (state) => state.isLoading,
          builder: (context, isLoading) {
            return AppButton(
              label: 'branches.edit_branch.save_button'.tr(),
              isLoading: isLoading,
              onPressed: (!canSave || isLoading) ? null : onSave,
            );
          },
        );
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
              label: 'common.next'.tr(),
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
            label: 'common.add'.tr(),
            onPressed: onAddCoverage,
          );
        }
        return AppButton(
          label: 'common.next'.tr(),
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
            label: 'common.add'.tr(),
            onPressed: onAddServices,
          );
        }
        return AppButton(
          label: 'common.next'.tr(),
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
            label: 'common.add'.tr(),
            onPressed: onAddWorkers,
          );
        }
        // Advance to the review screen (`365:14892`) before submitting.
        return AppButton(
          label: 'common.next'.tr(),
          onPressed: onNext,
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddBranchBloc, AddBranchState, bool>(
      selector: (state) => state.isLoading,
      builder: (context, isLoading) {
        return AppButton(
          label: 'branches.add_branch.save_button'.tr(),
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        );
      },
    );
  }
}
