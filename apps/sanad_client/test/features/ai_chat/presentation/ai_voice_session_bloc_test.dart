import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

import '../support/composer_fakes.dart';
import '../support/voice_fakes.dart';

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

  group('starting', () {
    test('asks for the microphone then starts the session', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(session.startCount, 1);
        expect(bloc.state.status, AiVoiceSessionStatus.connecting);
      });
    });

    test('a refused microphone errors without starting', () async {
      permissions.microphone = AiPermissionOutcome.denied;

      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(session.startCount, 0);
        expect(bloc.state.status, AiVoiceSessionStatus.error);
        expect(bloc.state.failureKey, 'ai_chat.microphone_denied');
        expect(bloc.state.canOpenSettings, isFalse);
      });
    });

    test('a permanently refused microphone offers settings', () async {
      permissions.microphone = AiPermissionOutcome.permanentlyDenied;

      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(bloc.state.canOpenSettings, isTrue);
        expect(
          bloc.state.failureKey,
          'ai_chat.microphone_denied_permanently',
        );
      });
    });

    test('starting again while active is ignored', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        await session.emitStatus(AiVoiceSessionStatus.listening);

        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(session.startCount, 1);
      });
    });

    test('a retry after a failure clears the old failure', () async {
      permissions.microphone = AiPermissionOutcome.denied;

      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        expect(bloc.state.failureKey, isNotNull);

        permissions.microphone = AiPermissionOutcome.granted;
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();

        expect(bloc.state.failureKey, isNull);
        expect(bloc.state.canOpenSettings, isFalse);
      });
    });
  });

  group('the lifecycle mirrors the session', () {
    test('every transition reaches the state', () async {
      await withBloc((bloc) async {
        final seen = <AiVoiceSessionStatus>[];
        final sub = bloc.stream.listen((s) => seen.add(s.status));

        for (final status in [
          AiVoiceSessionStatus.connecting,
          AiVoiceSessionStatus.listening,
          AiVoiceSessionStatus.processing,
          AiVoiceSessionStatus.speaking,
          AiVoiceSessionStatus.listening,
          AiVoiceSessionStatus.ending,
          AiVoiceSessionStatus.ended,
        ]) {
          await session.emitStatus(status);
        }
        await pumpEventQueue();

        expect(seen, [
          AiVoiceSessionStatus.connecting,
          AiVoiceSessionStatus.listening,
          AiVoiceSessionStatus.processing,
          AiVoiceSessionStatus.speaking,
          AiVoiceSessionStatus.listening,
          AiVoiceSessionStatus.ending,
          AiVoiceSessionStatus.ended,
        ]);

        await sub.cancel();
      });
    });

    test('an error carries the session key', () async {
      session.failureKey = 'ai_chat.voice_microphone_unavailable';

      await withBloc((bloc) async {
        await session.emitStatus(AiVoiceSessionStatus.error);
        await pumpEventQueue();

        expect(
          bloc.state.failureKey,
          'ai_chat.voice_microphone_unavailable',
        );
      });
    });

    test('an error with no key falls back to a generic one', () async {
      await withBloc((bloc) async {
        await session.emitStatus(AiVoiceSessionStatus.error);
        await pumpEventQueue();

        expect(bloc.state.failureKey, 'ai_chat.voice_error');
      });
    });

    test('canInterrupt is true only while speaking', () async {
      await withBloc((bloc) async {
        await session.emitStatus(AiVoiceSessionStatus.listening);
        await pumpEventQueue();
        expect(bloc.state.canInterrupt, isFalse);

        await session.emitStatus(AiVoiceSessionStatus.speaking);
        await pumpEventQueue();
        expect(bloc.state.canInterrupt, isTrue);
      });
    });
  });

  group('controls', () {
    test('mute toggles and tells the session', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionMuteToggled());
        await pumpEventQueue();
        expect(bloc.state.isMuted, isTrue);
        expect(session.muteCalls, [true]);

        bloc.add(const AiVoiceSessionMuteToggled());
        await pumpEventQueue();
        expect(bloc.state.isMuted, isFalse);
        expect(session.muteCalls, [true, false]);
      });
    });

    test('muting silences the level immediately', () async {
      await withBloc((bloc) async {
        await session.emitLevel(0.8);
        expect(bloc.level.value, closeTo(0.8, 0.001));

        bloc.add(const AiVoiceSessionMuteToggled());
        await pumpEventQueue();

        expect(bloc.level.value, 0);
      });
    });

    test('interrupt reaches the session', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionInterrupted());
        await pumpEventQueue();

        expect(session.interruptCount, 1);
      });
    });

    test('end reaches the session and silences the level', () async {
      await withBloc((bloc) async {
        await session.emitLevel(0.5);

        bloc.add(const AiVoiceSessionEndRequested());
        await pumpEventQueue();

        expect(session.endCount, 1);
        expect(bloc.level.value, 0);
      });
    });

    test('requesting settings opens them', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionSettingsRequested());
        await pumpEventQueue();

        expect(permissions.settingsOpened, 1);
      });
    });
  });

  group('the level stays off bloc state', () {
    test('level readings update the controller and emit NO state', () async {
      await withBloc((bloc) async {
        final states = <AiVoiceSessionState>[];
        final sub = bloc.stream.listen(states.add);

        for (var i = 1; i <= 30; i++) {
          await session.emitLevel(i / 30);
        }

        expect(
          states,
          isEmpty,
          reason: '30 audio frames must not emit a single bloc state',
        );
        expect(bloc.level.value, closeTo(1, 0.001));

        await sub.cancel();
      });
    });
  });

  group('disposal', () {
    test('close disposes the session, releasing the microphone', () async {
      final bloc = build();
      await bloc.close();

      expect(session.disposeCount, 1);
    });

    test('close mid-session still disposes', () async {
      final bloc = build()..add(const AiVoiceSessionStartRequested());
      await pumpEventQueue();
      await session.emitStatus(AiVoiceSessionStatus.listening);

      await bloc.close();

      expect(session.disposeCount, 1);
    });

    test('closing twice is safe', () async {
      final bloc = build();
      await bloc.close();
      await bloc.close();

      expect(session.disposeCount, 1);
    });
  });

  // Regression for A-05: the close control ended the session but never left
  // the screen, so the user was stranded on a page labelled "Session ended"
  // with the system back gesture as the only way out.
  group('closing the screen', () {
    test('tears the session down and asks the route to pop', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        session.statusController.add(AiVoiceSessionStatus.listening);
        await pumpEventQueue();

        bloc.add(const AiVoiceSessionCloseRequested());
        await pumpEventQueue();

        expect(session.endCount, 1);
        expect(bloc.state.closeRequested, isTrue);
      });
    });

    test('closing from idle still asks to pop, without ending twice', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionCloseRequested());
        await pumpEventQueue();

        // Nothing was running, so there is nothing to tear down — but the
        // user still asked to leave and must not be stranded.
        expect(session.endCount, 0);
        expect(bloc.state.closeRequested, isTrue);
      });
    });

    test('closing after the session already ended is safe', () async {
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        session.statusController.add(AiVoiceSessionStatus.ended);
        await pumpEventQueue();

        bloc.add(const AiVoiceSessionCloseRequested());
        await pumpEventQueue();

        expect(session.endCount, 0);
        expect(bloc.state.closeRequested, isTrue);
      });
    });

    test('repeated taps end the session once and stay latched', () async {
      // The user will tap more than once, because the first tap used to do
      // nothing visible.
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        session.statusController.add(AiVoiceSessionStatus.listening);
        await pumpEventQueue();

        bloc
          ..add(const AiVoiceSessionCloseRequested())
          ..add(const AiVoiceSessionCloseRequested())
          ..add(const AiVoiceSessionCloseRequested());
        await pumpEventQueue();

        expect(session.endCount, 1);
        expect(bloc.state.closeRequested, isTrue);
      });
    });

    test('ending the session on its own never asks the route to pop', () async {
      // The distinction that matters: plain end must not close the screen.
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        session.statusController.add(AiVoiceSessionStatus.listening);
        await pumpEventQueue();

        bloc.add(const AiVoiceSessionEndRequested());
        await pumpEventQueue();

        expect(session.endCount, 1);
        expect(bloc.state.closeRequested, isFalse);
      });
    });

    test('backgrounding ends the session but leaves the screen open', () async {
      // Otherwise taking a phone call would yank the voice screen away.
      await withBloc((bloc) async {
        bloc.add(const AiVoiceSessionStartRequested());
        await pumpEventQueue();
        session.statusController.add(AiVoiceSessionStatus.listening);
        await pumpEventQueue();

        bloc.add(const AiVoiceSessionBackgrounded());
        await pumpEventQueue();

        expect(session.endCount, 1);
        expect(bloc.state.closeRequested, isFalse);
      });
    });
  });
}
