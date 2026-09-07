part of 'add_branch_wizard_bloc.dart';

sealed class AddBranchWizardEvent extends Equatable {
  const AddBranchWizardEvent();

  @override
  List<Object?> get props => [];
}

final class AddBranchWizardAdvancedTo extends AddBranchWizardEvent {
  const AddBranchWizardAdvancedTo(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

final class AddBranchWizardStepTapped extends AddBranchWizardEvent {
  const AddBranchWizardStepTapped(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

final class AddBranchWizardBackPressed extends AddBranchWizardEvent {
  const AddBranchWizardBackPressed();
}

final class AddBranchWizardStepOneErrorsShown extends AddBranchWizardEvent {
  const AddBranchWizardStepOneErrorsShown();
}
