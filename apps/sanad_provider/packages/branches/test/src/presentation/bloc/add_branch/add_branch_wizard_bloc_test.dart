import 'package:bloc_test/bloc_test.dart';
import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddBranchWizardBloc', () {
    AddBranchWizardBloc build() => AddBranchWizardBloc(totalSteps: 4);

    test('starts at step 1 with furthest = 1', () {
      final bloc = build();
      addTearDown(bloc.close);
      expect(bloc.state.currentStep, 1);
      expect(bloc.state.furthestStep, 1);
      expect(bloc.state.showStepOneErrors, isFalse);
    });

    blocTest<AddBranchWizardBloc, AddBranchWizardState>(
      'advanceTo extends furthestStep monotonically',
      build: build,
      act: (bloc) => bloc
        ..advanceTo(2)
        ..advanceTo(3)
        ..advanceTo(1),
      verify: (bloc) {
        expect(bloc.state.currentStep, 1);
        expect(bloc.state.furthestStep, 3);
      },
    );

    blocTest<AddBranchWizardBloc, AddBranchWizardState>(
      'tapStep rejects taps past furthestStep',
      build: build,
      act: (bloc) => bloc
        ..advanceTo(2)
        ..tapStep(4)
        ..tapStep(1),
      verify: (bloc) => expect(bloc.state.currentStep, 1),
    );

    blocTest<AddBranchWizardBloc, AddBranchWizardState>(
      'showStepOneErrors flips the flag',
      build: build,
      act: (bloc) => bloc.showStepOneErrors(),
      verify: (bloc) => expect(bloc.state.showStepOneErrors, isTrue),
    );

    group('goBack', () {
      blocTest<AddBranchWizardBloc, AddBranchWizardState>(
        'is a no-op on step 1',
        build: build,
        act: (bloc) => bloc.goBack(),
        verify: (bloc) {
          expect(bloc.state.currentStep, 1);
          expect(bloc.state.furthestStep, 1);
        },
      );

      blocTest<AddBranchWizardBloc, AddBranchWizardState>(
        'moves back exactly one step and preserves furthestStep',
        build: build,
        act: (bloc) => bloc
          ..advanceTo(2)
          ..advanceTo(3)
          ..advanceTo(4)
          ..goBack()
          ..goBack()
          ..goBack(),
        verify: (bloc) {
          expect(bloc.state.currentStep, 1);
          expect(bloc.state.furthestStep, 4);
        },
      );

      blocTest<AddBranchWizardBloc, AddBranchWizardState>(
        'goes back from the review step to step 4',
        build: build,
        act: (bloc) => bloc
          ..advanceTo(5)
          ..goBack(),
        verify: (bloc) => expect(bloc.state.currentStep, 4),
      );
    });
  });
}
