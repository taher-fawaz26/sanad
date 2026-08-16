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
    this.currentStep = 1,
    this.furthestStep = 1,
    this.showStepOneErrors = false,
    this.coverageAccessDenied = false,
  });

  final int currentStep;
  final int furthestStep;

  /// True after the user tries to advance from step 1 with invalid input —
  /// flips inline field validators on.
  final bool showStepOneErrors;

  /// True when location permission is hard-denied while opening the coverage
  /// step — swaps in the "Location access needed" body.
  final bool coverageAccessDenied;

  AddBranchWizardState copyWith({
    int? currentStep,
    int? furthestStep,
    bool? showStepOneErrors,
    bool? coverageAccessDenied,
  }) => AddBranchWizardState(
    currentStep: currentStep ?? this.currentStep,
    furthestStep: furthestStep ?? this.furthestStep,
    showStepOneErrors: showStepOneErrors ?? this.showStepOneErrors,
    coverageAccessDenied: coverageAccessDenied ?? this.coverageAccessDenied,
  );

  @override
  List<Object?> get props => [
    currentStep,
    furthestStep,
    showStepOneErrors,
    coverageAccessDenied,
  ];
}

class AddBranchWizardCubit extends Cubit<AddBranchWizardState> {
  AddBranchWizardCubit({required int totalSteps})
    : _totalSteps = totalSteps,
      super(const AddBranchWizardState());

  final int _totalSteps;

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

  void showStepOneErrors() => emit(state.copyWith(showStepOneErrors: true));

  void setCoverageAccessDenied({required bool denied}) {
    if (state.coverageAccessDenied == denied) return;
    emit(state.copyWith(coverageAccessDenied: denied));
  }

  /// Highest step index (inclusive of the review step). Exposed so the page
  /// can pass identical constants for both stepper UI and step routing.
  int get totalSteps => _totalSteps;
}
