import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_hold_to_record_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_recording_gesture.dart';
import 'package:testing/testing.dart';

/// The record gesture, driven pointer by pointer.
///
/// Every assertion here is about which *intent* leaves the widget. What each
/// intent then does to the recorder lives in `ai_composer_bloc_test.dart`
/// against real fakes; this file's job is that a finger produces the right one.
///
/// A mocked bloc for the reason `ai_composer_widget_test.dart` documents:
/// `testWidgets` runs in a `FakeAsync` zone where a real composer bloc never
/// settles.
class MockAiComposerBloc extends MockBloc<AiComposerEvent, AiComposerState>
    implements AiComposerBloc {}

void main() {
  late MockAiComposerBloc bloc;

  setUp(() {
    bloc = MockAiComposerBloc();
    whenListen(
      bloc,
      const Stream<AiComposerState>.empty(),
      initialState: const AiComposerState(),
    );
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    bool screenReader = false,
    ValueChanged<Offset>? onDragUpdate,
  }) => pumpDsWidget(
    tester,
    MediaQuery(
      data: MediaQueryData(accessibleNavigation: screenReader),
      child: Directionality(
        textDirection: direction,
        child: BlocProvider<AiComposerBloc>.value(
          value: bloc,
          child: Scaffold(
            body: Center(
              child: AiHoldToRecordButton(
                onDragUpdate: onDragUpdate ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final mic = find.byType(AiHoldToRecordButton);

  /// Presses, holds past the activation deadline, and leaves the finger down.
  Future<TestGesture> hold(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(mic));
    // Past the deadline, so the recognizer accepts and `onLongPressStart`
    // fires. Nothing before this point may start a take.
    await tester.pump(AiRecordingGesture.holdActivation + kPressTimeout);
    return gesture;
  }

  group('a take begins only on a deliberate hold', () {
    testWidgets('a tap is a hint, not a recording', (tester) async {
      await pumpButton(tester);

      await tester.tap(mic);
      await tester.pump();

      verify(
        () => bloc.add(const AiComposerRecordingHintRequested()),
      ).called(1);
      verifyNever(() => bloc.add(const AiComposerRecordingStarted()));
    });

    testWidgets('a press released before the deadline starts nothing', (
      tester,
    ) async {
      await pumpButton(tester);

      final gesture = await tester.startGesture(tester.getCenter(mic));
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pump();

      verifyNever(() => bloc.add(const AiComposerRecordingStarted()));
    });

    testWidgets('holding past the deadline starts a take', (tester) async {
      await pumpButton(tester);

      final gesture = await hold(tester);

      verify(() => bloc.add(const AiComposerRecordingStarted())).called(1);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('releasing a held take stops it', (tester) async {
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.up();
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingStopped())).called(1);
      verifyNever(() => bloc.add(const AiComposerRecordingCancelled()));
    });
  });

  group('swiping up locks the take', () {
    testWidgets('past the threshold it locks', (tester) async {
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(0, -AiRecordingGesture.lockDistance - 8),
      );
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingLocked())).called(1);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('short of the threshold it does not', (tester) async {
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(0, -AiRecordingGesture.lockDistance + 8),
      );
      await tester.pump();

      verifyNever(() => bloc.add(const AiComposerRecordingLocked()));
      await gesture.up();
      await tester.pump();
    });

    testWidgets('releasing a locked take does not stop it', (tester) async {
      // The whole point of locking: the finger stops being what holds the take
      // open, so lifting it must say nothing at all.
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(0, -AiRecordingGesture.lockDistance - 8),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingLocked())).called(1);
      verifyNever(() => bloc.add(const AiComposerRecordingStopped()));
      verifyNever(() => bloc.add(const AiComposerRecordingCancelled()));
    });

    testWidgets('it locks once, however far the finger travels', (
      tester,
    ) async {
      await pumpButton(tester);

      final gesture = await hold(tester);
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(
          const Offset(0, -AiRecordingGesture.lockDistance),
        );
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingLocked())).called(1);
    });
  });

  group('swiping toward the leading edge discards the take', () {
    testWidgets('leading is left under LTR', (tester) async {
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(-AiRecordingGesture.cancelDistance - 8, 0),
      );
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingCancelled())).called(1);
      await gesture.up();
      await tester.pump();
      // The release must not also arrive: one terminal intent per sequence.
      verifyNever(() => bloc.add(const AiComposerRecordingStopped()));
    });

    testWidgets('leading is right under RTL', (tester) async {
      // The gesture mirrors so it reads as "push it back where it came from"
      // in both directions. A hard-coded negative dx would make cancelling
      // impossible in Arabic.
      await pumpButton(tester, direction: TextDirection.rtl);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(AiRecordingGesture.cancelDistance + 8, 0),
      );
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingCancelled())).called(1);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('dragging the wrong way under RTL does not cancel', (
      tester,
    ) async {
      await pumpButton(tester, direction: TextDirection.rtl);

      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(-AiRecordingGesture.cancelDistance - 8, 0),
      );
      await tester.pump();

      verifyNever(() => bloc.add(const AiComposerRecordingCancelled()));
      await gesture.up();
      await tester.pump();
    });
  });

  group('a sequence the system takes away', () {
    testWidgets('a cancelled pointer discards a live take', (tester) async {
      // What the first-ever permission dialog does: it steals the pointer, and
      // the recognizer reports a cancellation on a press that had already
      // started.
      await pumpButton(tester);

      final gesture = await hold(tester);
      await gesture.cancel();
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingCancelled())).called(1);
    });

    testWidgets('disposal discards an unlocked take', (tester) async {
      await pumpButton(tester);
      final gesture = await hold(tester);

      // The composer goes away with a finger still down. Nothing else will
      // ever release the take.
      await pumpDsWidget(tester, const SizedBox());
      await tester.pump();

      verify(() => bloc.add(const AiComposerRecordingCancelled())).called(1);
      await gesture.cancel();
    });

    testWidgets('disposal leaves a locked take alone', (tester) async {
      // A locked take is hands-free on purpose; discarding it because the
      // widget rebuilt elsewhere would throw away a recording nobody asked to
      // lose.
      await pumpButton(tester);
      final gesture = await hold(tester);
      await gesture.moveBy(
        const Offset(0, -AiRecordingGesture.lockDistance - 8),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      await pumpDsWidget(tester, const SizedBox());
      await tester.pump();

      verifyNever(() => bloc.add(const AiComposerRecordingCancelled()));
    });
  });

  group('the gesture is never the only way in', () {
    testWidgets('with a screen reader, a tap starts a locked take', (
      tester,
    ) async {
      // Holding a control for the length of a message is not an interaction
      // every user can perform. Locked from the outset means the explicit stop
      // and delete controls are the whole interaction.
      await pumpButton(tester, screenReader: true);

      await tester.tap(mic);
      await tester.pump();

      verify(
        () => bloc.add(const AiComposerRecordingStarted(autoLock: true)),
      ).called(1);
      // "Hold the microphone" would be wrong advice here — tap *is* the
      // gesture in this mode.
      verifyNever(() => bloc.add(const AiComposerRecordingHintRequested()));
    });

    testWidgets('the control is named whichever path is installed', (
      tester,
    ) async {
      await pumpButton(tester);
      expect(find.bySemanticsLabel('ai_chat.record_start'), findsOneWidget);

      await pumpButton(tester, screenReader: true);
      expect(find.bySemanticsLabel('ai_chat.record_start'), findsOneWidget);
    });
  });

  group('the drag is reported off bloc state', () {
    testWidgets('it follows the finger and clears on release', (tester) async {
      final offsets = <Offset>[];
      await pumpButton(tester, onDragUpdate: offsets.add);

      final gesture = await hold(tester);
      await gesture.moveBy(const Offset(-20, -20));
      await tester.pump();

      expect(offsets.last, const Offset(-20, -20));

      await gesture.up();
      await tester.pump();

      // Zero means "the gesture is over", so the rails snap back rather than
      // staying frozen wherever the finger left them.
      expect(offsets.last, Offset.zero);
      // Not one state emission for any of it.
      verifyNever(() => bloc.add(const AiComposerRecordingLocked()));
    });
  });
}
