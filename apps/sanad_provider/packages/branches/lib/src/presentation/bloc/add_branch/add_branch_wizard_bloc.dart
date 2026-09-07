import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_branch_wizard_event.dart';

/// UI-only state for the [AddBranchPage] wizard: which step is current,
/// which is the furthest reachable, and a handful of surfacing flags for
/// dialogs / permission screens that used to live as mutable fields on the
/// State class.
///
/// The bloc has no dependencies — it just tracks the wizard's navigation
/// and the "am I currently showing X" booleans. Actual data (draft form
/// values, submission status) still belongs to [AddBranchDraftBloc] and
/// [AddBranchBloc].
class AddBranchWizardState extends Equatable {
  const AddBranchWizardState({
    this.currentStep = 1,
    this.furthestStep = 1,
    this.showStepOneErrors = false,
  });

  final int currentStep;
  final int furthestStep;

  /// True after the user tries to advance from step 1 with invalid input —
  /// flips inline field validators on.
  final bool showStepOneErrors;

  AddBranchWizardState copyWith({
    int? currentStep,
    int? furthestStep,
    bool? showStepOneErrors,
  }) => AddBranchWizardState(
    currentStep: currentStep ?? this.currentStep,
    furthestStep: furthestStep ?? this.furthestStep,
    showStepOneErrors: showStepOneErrors ?? this.showStepOneErrors,
  );

  @override
  List<Object?> get props => [currentStep, furthestStep, showStepOneErrors];
}

class AddBranchWizardBloc
    extends Bloc<AddBranchWizardEvent, AddBranchWizardState> {
  AddBranchWizardBloc({required int totalSteps})
    : _totalSteps = totalSteps,
      super(const AddBranchWizardState()) {
    on<AddBranchWizardAdvancedTo>(_onAdvancedTo);
    on<AddBranchWizardStepTapped>(_onStepTapped);
    on<AddBranchWizardBackPressed>(_onBackPressed);
    on<AddBranchWizardStepOneErrorsShown>(_onStepOneErrorsShown);
  }

  final int _totalSteps;

  /// Highest step index (inclusive of the review step). Exposed so the page
  /// can pass identical constants for both stepper UI and step routing.
  int get totalSteps => _totalSteps;

  // Imperative helpers dispatch the corresponding event — kept so call
  // sites already using `wizard.advanceTo(step)` etc. don't need to be
  // rewritten. All state mutation still routes through the event handlers
  // below.

  /// Jumps to [step], extending [furthestStep] as needed.
  void advanceTo(int step) => add(AddBranchWizardAdvancedTo(step));

  /// Handles a stepper tap. Rejects taps past [furthestStep].
  void tapStep(int step) => add(AddBranchWizardStepTapped(step));

  /// Moves back exactly one step (the nav-bar back action). No-op on step 1.
  void goBack() => add(const AddBranchWizardBackPressed());

  void showStepOneErrors() => add(const AddBranchWizardStepOneErrorsShown());

  void _onAdvancedTo(
    AddBranchWizardAdvancedTo event,
    Emitter<AddBranchWizardState> emit,
  ) => emit(
    state.copyWith(
      currentStep: event.step,
      furthestStep: event.step > state.furthestStep
          ? event.step
          : state.furthestStep,
    ),
  );

  void _onStepTapped(
    AddBranchWizardStepTapped event,
    Emitter<AddBranchWizardState> emit,
  ) {
    if (event.step > state.furthestStep) return;
    emit(state.copyWith(currentStep: event.step));
  }

  void _onBackPressed(
    AddBranchWizardBackPressed event,
    Emitter<AddBranchWizardState> emit,
  ) {
    if (state.currentStep <= 1) return;
    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  void _onStepOneErrorsShown(
    AddBranchWizardStepOneErrorsShown event,
    Emitter<AddBranchWizardState> emit,
  ) => emit(state.copyWith(showStepOneErrors: true));
}
