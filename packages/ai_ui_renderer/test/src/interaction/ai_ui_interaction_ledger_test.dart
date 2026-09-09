import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AiUiInteractionLedger ledger;

  setUp(() => ledger = AiUiInteractionLedger());
  tearDown(() => ledger.dispose());

  group('the default', () {
    test('a node nobody has touched is answerable', () {
      expect(ledger.stateOf('n_1'), AiUiNodeInteractionState.active);
      expect(ledger.canSubmit('n_1'), isTrue);
    });

    test('reading a state does not create a listener that is never freed', () {
      // Two reads of the same id hand back the same notifier, so a card that
      // rebuilds does not churn subscriptions.
      expect(identical(ledger.watch('n_1'), ledger.watch('n_1')), isTrue);
    });
  });

  group('duplicate submission', () {
    test('the second claim is refused while the first is in flight', () {
      expect(ledger.beginSubmission('n_1'), isTrue);
      expect(ledger.beginSubmission('n_1'), isFalse);
      expect(ledger.stateOf('n_1'), AiUiNodeInteractionState.pending);
    });

    test('an answered node refuses a second answer', () {
      ledger
        ..beginSubmission('n_1')
        ..markSubmitted('n_1');

      expect(ledger.beginSubmission('n_1'), isFalse);
      expect(ledger.stateOf('n_1'), AiUiNodeInteractionState.submitted);
    });

    test('a cancelled node refuses a later answer', () {
      ledger
        ..beginSubmission('n_1')
        ..markCancelled('n_1');

      expect(ledger.beginSubmission('n_1'), isFalse);
    });

    test('claims are per node — answering one leaves the others alone', () {
      expect(ledger.beginSubmission('n_1'), isTrue);

      expect(ledger.canSubmit('n_2'), isTrue);
      expect(ledger.stateOf('n_2'), AiUiNodeInteractionState.active);
    });
  });

  group('failure is not terminal', () {
    test('a failed send makes the node answerable again', () {
      ledger
        ..beginSubmission('n_1')
        ..markFailed('n_1');

      expect(ledger.stateOf('n_1'), AiUiNodeInteractionState.failed);
      expect(ledger.canSubmit('n_1'), isTrue);
      expect(ledger.beginSubmission('n_1'), isTrue);
    });

    test('a failed node still reads as interactive, so it is not dead', () {
      ledger
        ..beginSubmission('n_1')
        ..markFailed('n_1');

      expect(ledger.stateOf('n_1').isInteractive, isTrue);
    });

    test('reset returns a stranded pending node to answerable', () {
      // What a voice session ending mid-question does: nothing will ever
      // resolve the claim, so the card must not stay disabled.
      ledger
        ..beginSubmission('n_1')
        ..reset('n_1');

      expect(ledger.stateOf('n_1'), AiUiNodeInteractionState.active);
    });
  });

  group('notification', () {
    test('only the node that changed notifies', () {
      var first = 0;
      var second = 0;
      ledger.watch('n_1').addListener(() => first++);
      ledger.watch('n_2').addListener(() => second++);

      ledger.beginSubmission('n_1');

      expect(first, 1);
      expect(second, 0);
    });

    test('a repeated state change does not notify twice', () {
      var calls = 0;
      ledger.watch('n_1').addListener(() => calls++);

      ledger
        ..markSubmitted('n_1')
        ..markSubmitted('n_1');

      expect(calls, 1);
    });
  });

  group('disposal', () {
    test('is safe to call twice', () {
      final subject = AiUiInteractionLedger()..beginSubmission('n_1');

      expect(subject.dispose, returnsNormally);
      expect(subject.dispose, returnsNormally);
    });

    test('a disposed ledger accepts no further claims', () {
      final subject = AiUiInteractionLedger()..dispose();

      expect(subject.beginSubmission('n_1'), isFalse);
      expect(() => subject.markSubmitted('n_1'), returnsNormally);
    });
  });

  group('the state predicates', () {
    test('only active and failed accept a submission', () {
      final accepting = AiUiNodeInteractionState.values
          .where((s) => s.acceptsSubmission)
          .toSet();

      expect(accepting, {
        AiUiNodeInteractionState.active,
        AiUiNodeInteractionState.failed,
      });
    });

    test('pending is not interactive, which is what stops a double tap', () {
      expect(AiUiNodeInteractionState.pending.isInteractive, isFalse);
    });
  });
}
