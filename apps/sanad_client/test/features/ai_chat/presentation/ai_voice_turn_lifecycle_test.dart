import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

import '../support/composer_fakes.dart';
import '../support/voice_fakes.dart';

/// The Live Voice turn lifecycle, driven from ONE control.
///
/// The approved design runs the whole conversation from a single circular
/// button whose meaning comes from the session status:
///
/// ```text
/// idle      -> tap -> listening      (start)
/// listening -> tap -> processing     (finish turn)
/// processing-> ...  -> speaking      (the session decides)
/// speaking  -> tap -> listening      (interrupt / barge-in)
/// ```
///
/// These tests pin the two things that make that safe: each tap reaches the
/// session through an event the bloc already owns, and the bloc never
/// *predicts* the next status — it waits for the session to report it. A UI
/// that optimistically emitted `processing` on tap would drift out of sync the
/// moment a session refused the transition.
///
/// Plain `flutter_test`, matching `ai_voice_session_bloc_test.dart` —
/// `bloc_test` is not a dependency of this app.
void main() {
  late FakeVoiceSession session;
  late FakePermissionGateway permissions;

  AiVoiceSessionBloc build() =>
      AiVoiceSessionBloc(session: session, permissions: permissions);

  setUp(() {
    session = FakeVoiceSession();
    permissions = FakePermissionGateway();
  });

  Future<void> withBloc(
    Future<void> Function(AiVoiceSessionBloc bloc) body,
  ) async {
    final bloc = build();
    try {
      await body(bloc);
    } finally {
      await bloc.close();
    }
  }

  /// Drives the bloc to [status] the way the session would, so each test
  /// starts from a real reported transition rather than a hand-built state.
  Future<void> reach(
    AiVoiceSessionBloc bloc,
    AiVoiceSessionStatus status,
  ) async {
    await session.emitStatus(status);
    await pumpEventQueue();
    expect(bloc.state.status, status);
  }

  group('one button, four meanings', () {
    test('a tap while idle starts the session', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(session.startCount, 1);
      });
    });

    test('a tap while listening ends the user turn and nothing else', () async {
      await withBloc((bloc) async {
        await reach(bloc, AiVoiceSessionStatus.listening);

        bloc.add(const AiVoiceSessionTurnFinished());
        await pumpEventQueue();

        expect(session.finishTurnCount, 1);
        // Ending a turn is not interrupting the assistant and is not hanging
        // up — the three must never be conflated behind one control.
        expect(session.interruptCount, 0);
        expect(session.endCount, 0);
      });
    });

    test(
      'a tap while speaking interrupts, it does not end the session',
      () async {
        await withBloc((bloc) async {
          await reach(bloc, AiVoiceSessionStatus.speaking);

          bloc.add(const AiVoiceSessionInterrupted());
          await pumpEventQueue();

          expect(session.interruptCount, 1);
          expect(session.endCount, 0);
          expect(session.finishTurnCount, 0);
        });
      },
    );

    test(
      'finishing a turn does not move the status by itself — the session is '
      'what the UI follows, so the button can never disagree with it',
      () async {
        await withBloc((bloc) async {
          await reach(bloc, AiVoiceSessionStatus.listening);

          bloc.add(const AiVoiceSessionTurnFinished());
          await pumpEventQueue();

          // No optimistic jump to processing.
          expect(bloc.state.status, AiVoiceSessionStatus.listening);
        });
      },
    );

    test(
      'the session reporting processing then speaking moves the UI',
      () async {
        await withBloc((bloc) async {
          await reach(bloc, AiVoiceSessionStatus.listening);

          bloc.add(const AiVoiceSessionTurnFinished());
          await pumpEventQueue();

          await reach(bloc, AiVoiceSessionStatus.processing);
          await reach(bloc, AiVoiceSessionStatus.speaking);
        });
      },
    );

    test('barge-in returns to listening, ready for the next turn', () async {
      await withBloc((bloc) async {
        await reach(bloc, AiVoiceSessionStatus.speaking);

        bloc.add(const AiVoiceSessionInterrupted());
        await pumpEventQueue();
        await reach(bloc, AiVoiceSessionStatus.listening);

        // ...and the same control ends that new turn.
        bloc.add(const AiVoiceSessionTurnFinished());
        await pumpEventQueue();

        expect(session.finishTurnCount, 1);
      });
    });
  });

  group('close', () {
    test(
      'the close control ends the session, releasing microphone and audio',
      () async {
        await withBloc((bloc) async {
          await reach(bloc, AiVoiceSessionStatus.speaking);

          bloc.add(const AiVoiceSessionEndRequested());
          await pumpEventQueue();

          expect(session.endCount, 1);
        });
      },
    );

    test('closing the bloc disposes the session exactly once', () async {
      final bloc = build();
      await bloc.close();

      expect(session.disposeCount, 1);
    });
  });
}
