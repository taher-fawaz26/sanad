import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddBranchWizardCubit', () {
    late AddBranchWizardCubit cubit;

    setUp(() {
      cubit = AddBranchWizardCubit(totalSteps: 4);
    });

    tearDown(() => cubit.close());

    test('starts at step 1 with furthest = 1', () {
      expect(cubit.state.currentStep, 1);
      expect(cubit.state.furthestStep, 1);
      expect(cubit.state.showStepOneErrors, isFalse);
      expect(cubit.state.coverageAccessDenied, isFalse);
    });

    test('advanceTo extends furthestStep monotonically', () {
      cubit
        ..advanceTo(2)
        ..advanceTo(3);
      expect(cubit.state.currentStep, 3);
      expect(cubit.state.furthestStep, 3);

      // Going back should not shrink furthestStep.
      cubit.advanceTo(1);
      expect(cubit.state.currentStep, 1);
      expect(cubit.state.furthestStep, 3);
    });

    test('tapStep rejects taps past furthestStep', () {
      cubit.advanceTo(2);
      cubit.tapStep(4);
      expect(cubit.state.currentStep, 2);

      cubit.tapStep(1);
      expect(cubit.state.currentStep, 1);
    });

    test('showStepOneErrors flips the flag', () {
      cubit.showStepOneErrors();
      expect(cubit.state.showStepOneErrors, isTrue);
    });

    test('setCoverageAccessDenied is a no-op when unchanged', () {
      final states = <AddBranchWizardState>[];
      final sub = cubit.stream.listen(states.add);

      cubit
        ..setCoverageAccessDenied(denied: false)
        ..setCoverageAccessDenied(denied: true)
        ..setCoverageAccessDenied(denied: true);
      return Future.microtask(() async {
        await sub.cancel();
        // Only one emission for the false→true transition.
        expect(states.length, 1);
        expect(states.single.coverageAccessDenied, isTrue);
      });
    });
  });
}
