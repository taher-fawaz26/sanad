@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/wav_header.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_ai_voice_session.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_voice_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_voice_event.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/audio_level_scale.dart';

import '../support/composer_fakes.dart';
import '../support/voice_fakes.dart';

/// The session writes utterances to the real temporary directory, which needs
/// the platform channel `path_provider` uses. These tests therefore stub it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVoiceCapture capture;
  late FakeAudioPlayer player;
  late AudioSessionManager session;
  late Directory tempDir;

  // Only the *delays* are collapsed, so the state machine runs at test speed.
  // `speechThreshold` and `bargeInThreshold` are deliberately left at their
  // production defaults — they are what these tests are actually about, and
  // overriding them would prove the test's own numbers rather than the app's.
  const tuning = AiVoiceTuning(
    connectDelay: Duration.zero,
    processingDelay: Duration.zero,
    silenceHold: Duration(milliseconds: 20),
    minUtterance: Duration.zero,
    bargeInGrace: Duration.zero,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ai_voice_test');
    _stubPathProvider(tempDir.path);
    capture = FakeVoiceCapture();
    player = FakeAudioPlayer();
    session = AudioSessionManager();
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    } on Object {
      // Windows can hold a handle open for a moment after the sink closes.
      // A scratch directory left behind must not fail an otherwise good test.
    }
  });

  MockAiVoiceSession build({AiVoiceUiScript? uiScript}) => MockAiVoiceSession(
    capture: capture,
    player: player,
    session: session,
    tuning: tuning,
    uiScript: uiScript,
  );

  /// Waits long enough for the silence hold to elapse in wall-clock terms.
  Future<void> passSilenceHold() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  /// Waits until [predicate] holds, or gives up.
  ///
  /// The session finalises an utterance with real file I/O, which does not
  /// complete on the microtask queue — so `pumpEventQueue` alone races it.
  /// Polling a predicate is both faster and steadier than a fixed sleep.
  Future<void> until(
    bool Function() predicate, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!predicate() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  group('the microphone is real', () {
    test('starting opens the capture and begins listening', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();

      expect(capture.startCount, 1);
      expect(seen, [
        AiVoiceSessionStatus.connecting,
        AiVoiceSessionStatus.listening,
      ]);

      await sub.cancel();
    });

    test('no microphone fails without opening anything', () async {
      capture.available = false;
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();

      expect(capture.startCount, 0);
      expect(voice.failureKey, 'ai_chat.voice_microphone_unavailable');
    });

    test('a capture that refuses to open errors cleanly', () async {
      capture.throwOnStart = true;
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();

      expect(voice.failureKey, 'ai_chat.voice_error');
    });

    test('real frames drive the level, computed from the PCM', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final levels = <double>[];
      final sub = voice.inputLevel.listen(levels.add);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.5);

      // What reaches the meter is the *display* level, not the raw RMS. Half
      // full scale is -6 dBFS, which on the shared scale is near the top —
      // whereas the raw 0.5 would draw a bar at half height for a signal that
      // is, in loudness terms, extremely loud.
      expect(levels, isNotEmpty);
      expect(levels.last, closeTo(AudioLevelScale.fromLinear(0.5), 0.001));
      expect(levels.last, greaterThan(0.8));

      await sub.cancel();
    });

    test('a louder frame reads higher than a quieter one', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final levels = <double>[];
      final sub = voice.inputLevel.listen(levels.add);

      await voice.start();
      await pumpEventQueue();

      await capture.emit(0.02);
      final quiet = levels.last;
      await capture.emit(0.2);
      final loud = levels.last;

      // The property that actually matters on screen, and the one the raw RMS
      // failed: speech must be visibly above room tone. Raw, these two differ
      // by 0.18 of the meter's travel; on the shared scale, by far more.
      expect(loud, greaterThan(quiet));
      expect(loud - quiet, greaterThan(0.2));

      await sub.cancel();
    });
  });

  group('silence ends the turn', () {
    test('speech then silence moves to processing and speaking', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();

      await capture.emit(0.6);
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => seen.contains(AiVoiceSessionStatus.speaking));

      expect(seen, contains(AiVoiceSessionStatus.processing));
      expect(seen, contains(AiVoiceSessionStatus.speaking));
      // The assistant's voice is the captured audio, played back.
      expect(player.played, hasLength(1));

      await sub.cancel();
    });

    test('silence with no speech never ends a turn', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();

      // Room tone only: below the speech threshold throughout.
      for (var i = 0; i < 10; i++) {
        await capture.emit(0.01);
      }
      await passSilenceHold();
      await capture.emit(0.01);
      await pumpEventQueue();

      expect(seen, isNot(contains(AiVoiceSessionStatus.processing)));
      expect(player.played, isEmpty);

      await sub.cancel();
    });

    test('a pause shorter than the hold does not end the turn', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();

      await capture.emit(0.6);
      // No wall-clock gap: the hold has not elapsed.
      await capture.emit(0);
      await pumpEventQueue();

      expect(seen, isNot(contains(AiVoiceSessionStatus.processing)));

      await sub.cancel();
    });

    test('the captured utterance is a playable WAV', () async {
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => player.playedPaths.isNotEmpty);

      expect(player.playedPaths, hasLength(1));
      final bytes = await File(player.playedPaths.single).readAsBytes();
      expect(bytes.length, greaterThan(WavHeader.byteLength));
      // "RIFF" ... "WAVE"
      expect(bytes.sublist(0, 4), [0x52, 0x49, 0x46, 0x46]);
      expect(bytes.sublist(8, 12), [0x57, 0x41, 0x56, 0x45]);

      // The declared payload length must match what was actually written, or
      // the player reads past the end and the reply is silence.
      final declared = ByteData.sublistView(
        Uint8List.fromList(bytes),
        40,
        44,
      ).getUint32(0, Endian.little);
      expect(declared, bytes.length - WavHeader.byteLength);
    });
  });

  group('speaking and barge-in', () {
    test('finishing the reply hands the turn back', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => seen.contains(AiVoiceSessionStatus.speaking));

      // The player reports it started, then finished.
      await player.emitProgress(
        const AiPlaybackProgress(
          position: Duration(seconds: 1),
          duration: Duration(seconds: 2),
          isPlaying: true,
        ),
      );
      await player.emitProgress(AiPlaybackProgress.idle);
      await pumpEventQueue();

      expect(
        seen.lastWhere((s) => s != AiVoiceSessionStatus.speaking),
        AiVoiceSessionStatus.listening,
      );

      await sub.cancel();
    });

    test('a loud frame while speaking interrupts the assistant', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => seen.contains(AiVoiceSessionStatus.speaking));
      expect(seen.last, AiVoiceSessionStatus.speaking);

      // Above the barge-in threshold: the user talks over the reply.
      await capture.emit(0.9);
      await pumpEventQueue();

      expect(player.stopCount, greaterThanOrEqualTo(1));
      expect(seen.last, AiVoiceSessionStatus.listening);

      await sub.cancel();
    });

    test('a quiet frame while speaking does not interrupt', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => seen.contains(AiVoiceSessionStatus.speaking));

      // Leakage from the speaker, below the barge-in threshold.
      await capture.emit(0.1);
      await pumpEventQueue();

      expect(seen.last, AiVoiceSessionStatus.speaking);

      await sub.cancel();
    });

    test('interrupting while not speaking does nothing', () async {
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();

      await voice.interrupt();
      await pumpEventQueue();

      expect(player.stopCount, 0);
    });
  });

  group('mute', () {
    test('muted frames neither record nor move the meter', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final levels = <double>[];
      final sub = voice.inputLevel.listen(levels.add);

      await voice.start();
      await pumpEventQueue();
      await voice.setMuted(muted: true);
      levels.clear();

      await capture.emit(0.9);
      await passSilenceHold();
      await capture.emit(0);
      await pumpEventQueue();

      // Nothing was heard, so no turn ended.
      expect(player.played, isEmpty);
      expect(levels.every((l) => l == 0), isTrue);

      await sub.cancel();
    });

    test('unmuting resumes without reopening the microphone', () async {
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();
      await voice.setMuted(muted: true);
      await voice.setMuted(muted: false);

      // Reopening would cost a permission round trip and make unmute feel
      // broken; the stream is simply ignored while muted.
      expect(capture.startCount, 1);
      expect(capture.stopCount, 0);
    });
  });

  group('teardown', () {
    test('ending stops the capture and the player', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);

      await voice.start();
      await pumpEventQueue();
      await voice.end();
      await pumpEventQueue();

      expect(capture.stopCount, greaterThanOrEqualTo(1));
      expect(seen.last, AiVoiceSessionStatus.ended);

      await sub.cancel();
    });

    test('ending leaves no scratch files behind', () async {
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);
      await passSilenceHold();
      await capture.emit(0);
      await until(() => player.playedPaths.isNotEmpty);

      await voice.end();
      await pumpEventQueue();

      final leftovers = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('ai_voice_'))
          .toList();
      expect(leftovers, isEmpty);
    });

    test('disposing mid-turn releases the microphone', () async {
      final voice = build();

      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.6);

      await voice.dispose();

      expect(capture.disposeCount, 1);
    });

    test('disposing twice is safe', () async {
      final voice = build();
      await voice.dispose();
      await voice.dispose();

      expect(capture.disposeCount, 1);
    });

    test('ending an already-ended session does nothing', () async {
      final voice = build();
      addTearDown(voice.dispose);

      await voice.start();
      await pumpEventQueue();
      await voice.end();
      await pumpEventQueue();
      final stops = capture.stopCount;

      await voice.end();
      await pumpEventQueue();

      expect(capture.stopCount, stops);
    });
  });

  group('a card can interrupt the conversation', () {
    /// The whole point of live voice being bidirectional: a document arrives
    /// mid-session, the assistant stops, the user answers by tapping, and the
    /// session resumes. Driven through the real state machine and the real
    /// utterance pipeline — only the decision to send a card is scripted.
    Future<void> speakOneTurn(MockAiVoiceSession voice) async {
      await voice.start();
      await pumpEventQueue();
      await capture.emit(0.5);
      await capture.emit(0.5);
      await capture.emit(0);
      await passSilenceHold();
      await capture.emit(0);
    }

    test('the assistant asks instead of speaking', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final events = <AiVoiceEvent>[];
      final sub = voice.events.listen(events.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(() => events.isNotEmpty);

      expect(events.single, isA<AiVoiceUiRequested>());
      expect(
        (events.single as AiVoiceUiRequested).payload,
        MockVoiceScenarios.timeSlots,
      );
    });

    test('the reply is held back until the card is answered', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(
        () => seen.contains(AiVoiceSessionStatus.awaitingInteraction),
      );

      // Talking over the question would be worse than saying nothing.
      expect(player.played.length, 0);
      expect(seen.last, AiVoiceSessionStatus.awaitingInteraction);
    });

    test('answering resumes the session', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(
        () => seen.contains(AiVoiceSessionStatus.awaitingInteraction),
      );

      await voice.submitInteraction(_answer);
      await until(() => player.played.isNotEmpty);

      expect(seen, contains(AiVoiceSessionStatus.speaking));
      expect(player.played.length, 1);
    });

    test('the answered card is taken down', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final events = <AiVoiceEvent>[];
      final sub = voice.events.listen(events.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(() => events.isNotEmpty);
      await voice.submitInteraction(_answer);
      await until(() => events.length > 1);

      expect(
        events.last,
        isA<AiVoiceUiResolved>().having(
          (e) => e.nodeId,
          'nodeId',
          'voice_slots',
        ),
      );
    });

    test('a second answer changes nothing', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      await speakOneTurn(voice);
      await until(() => player.played.isEmpty && capture.startCount > 0);
      await voice.submitInteraction(_answer);
      await until(() => player.played.isNotEmpty);

      await voice.submitInteraction(_answer);
      await pumpEventQueue();

      expect(player.played.length, 1);
    });

    test('ending mid-question takes the card down', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final events = <AiVoiceEvent>[];
      final sub = voice.events.listen(events.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(() => events.isNotEmpty);

      await voice.end();
      await pumpEventQueue();

      // A card left waiting for an answer nothing will receive is worse than
      // one taken down.
      expect(events.last, isA<AiVoiceUiResolved>());
      expect(events.whereType<AiVoiceUiResolved>().last.nodeId, isNull);
    });

    test('microphone frames are ignored while a card is up', () async {
      final voice = build(uiScript: MockVoiceScenarios.standard);
      addTearDown(voice.dispose);

      final seen = <AiVoiceSessionStatus>[];
      final sub = voice.status.listen(seen.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(
        () => seen.contains(AiVoiceSessionStatus.awaitingInteraction),
      );

      // Loud enough to barge in, and quiet enough to end a turn: neither may
      // fire, or a cough would answer the question.
      await capture.emit(0.9);
      await capture.emit(0);
      await passSilenceHold();
      await capture.emit(0);
      await pumpEventQueue();

      expect(seen.last, AiVoiceSessionStatus.awaitingInteraction);
      expect(player.played.length, 0);
    });

    test('without a script the session still just echoes', () async {
      final voice = build();
      addTearDown(voice.dispose);

      final events = <AiVoiceEvent>[];
      final sub = voice.events.listen(events.add);
      addTearDown(sub.cancel);

      await speakOneTurn(voice);
      await until(() => player.played.isNotEmpty);

      expect(events, isEmpty);
      expect(player.played.length, 1);
    });
  });
}

/// One answer, reused across the group above.
const _answer = AiUiInteraction(
  interactionId: 'int_1',
  nodeId: 'voice_slots',
  nodeType: AiUiNodeType.timeSlots,
  kind: AiUiInteractionKind.slotSelected,
  value: AiUiSelectionValue(id: 's_0900', label: '9:00 AM'),
  text: 'Book me the 9:00 AM slot',
);

/// `path_provider` is a platform channel; the session writes real files, so the
/// channel is answered with a real temporary directory instead of being faked
/// away. That keeps the WAV assertions honest — they read what was written.
void _stubPathProvider(String path) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => path,
      );
}
