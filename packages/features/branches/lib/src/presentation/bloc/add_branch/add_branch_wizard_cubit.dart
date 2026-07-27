import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// UI-only state for the [AddBranchPage] wizard: which step is current,
/// which is the furthest reachable, and a handful of surfacing flags for
/// dialogs / permission screens that used to live as mutable fields on the
/// State class.
///
/// The controller has no dependencies — it just tracks the wizard's
/// navigation and the "am I currently showing X" booleans. Actual data
/// (draft form values, submission status) still belongs to
/// `AddBranchDraftCubit` and `AddBranchBloc`.
class AddBranchWizardState extends Equatable {
  const AddBranchWizardState({
    required this.isEdit,
    this.currentStep = 1,
    this.furthestStep = 1,
    this.showStepOneErrors = false,
    this.isSeeded = true,
    this.coverageAccessDenied = false,
    this.submittingDialogVisible = false,
  });

  final bool isEdit;
  final int currentStep;
  final int furthestStep;

  /// True after the user tries to advance from step 1 with invalid input —
  /// flips inline field validators on.
  final bool showStepOneErrors;

  /// True once the edit-mode draft has been seeded from a fetched branch.
  /// Always true in create mode and in edit mode when the branch was
  /// pre-loaded.
  final bool isSeeded;

  /// True when location permission is hard-denied while opening the coverage
  /// step — swaps in the "Location access needed" body.
  final bool coverageAccessDenied;

  /// True while an app-progress dialog is on the stack for a submit / save.
  /// Owned here (not by the page) so a bloc listener can safely toggle it
  /// without racing a mutable field on the page's State.
  final bool submittingDialogVisible;

  AddBranchWizardState copyWith({
    int? currentStep,
    int? furthestStep,
    bool? showStepOneErrors,
    bool? isSeeded,
    bool? coverageAccessDenied,
    bool? submittingDialogVisible,
  }) => AddBranchWizardState(
    isEdit: isEdit,
    currentStep: currentStep ?? this.currentStep,
    furthestStep: furthestStep ?? this.furthestStep,
    showStepOneErrors: showStepOneErrors ?? this.showStepOneErrors,
    isSeeded: isSeeded ?? this.isSeeded,
    coverageAccessDenied: coverageAccessDenied ?? this.coverageAccessDenied,
    submittingDialogVisible:
        submittingDialogVisible ?? this.submittingDialogVisible,
  );

  @override
  List<Object?> get props => [
    isEdit,
    currentStep,
    furthestStep,
    showStepOneErrors,
    isSeeded,
    coverageAccessDenied,
    submittingDialogVisible,
  ];
}

class AddBranchWizardCubit extends Cubit<AddBranchWizardState> {
  AddBranchWizardCubit({required bool isEdit, required int totalSteps})
    : _totalSteps = totalSteps,
      super(
        AddBranchWizardState(
          isEdit: isEdit,
          // Edit mode lets the user tap any step from the start; create mode
          // walks the wizard linearly.
          furthestStep: isEdit ? totalSteps : 1,
          // Edit-with-preloaded-branch is seeded immediately; the id-only
          // fetch path flips this to false via [markSeedingRequired].
          isSeeded: true,
        ),
      );

  final int _totalSteps;

  /// Marks the wizard as awaiting a branch fetch before it can seed the
  /// draft. Called from the page's initState in edit-with-id mode.
  void markSeedingRequired() =>
      emit(state.copyWith(isSeeded: false));

  void markSeeded() => emit(state.copyWith(isSeeded: true));

  /// Jumps to [step], extending [furthestStep] as needed.
  void advanceTo(int step) => emit(
    state.copyWith(
      currentStep: step,
      furthestStep: step > state.furthestStep ? step : state.furthestStep,
    ),
  );

  /// Handles a stepper tap. Rejects taps past [furthestStep].
  void tapStep(int step) {
    if (step > state.furthestStep) return;
    emit(state.copyWith(currentStep: step));
  }

  void showStepOneErrors() =>
      emit(state.copyWith(showStepOneErrors: true));

  void setCoverageAccessDenied({required bool denied}) {
    if (state.coverageAccessDenied == denied) return;
    emit(state.copyWith(coverageAccessDenied: denied));
  }

  void markSubmittingDialogShown() =>
      emit(state.copyWith(submittingDialogVisible: true));

  void markSubmittingDialogDismissed() =>
      emit(state.copyWith(submittingDialogVisible: false));

  /// Highest step index (inclusive of the review step). Exposed so the page
  /// can pass identical constants for both stepper UI and step routing.
  int get totalSteps => _totalSteps;
}
