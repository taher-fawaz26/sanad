import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_recording_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/level_history.dart';

import '../support/attachment_fixtures.dart';
import '../support/composer_fakes.dart';

void main() {
  late FakeAttachmentSource source;
  late FakeAudioRecorder recorder;
  late FakeAudioPlayer player;
  late FakePermissionGateway permissions;
  late FakeSpeechRecognizer recognizer;
  late String languageCode;

  const rules = AiAttachmentRules();

  AiComposerBloc build() => AiComposerBloc(
    attachmentSource: source,
    recorder: recorder,
    player: player,
    permissions: permissions,
    recognizer: recognizer,
    resolveLanguageCode: () => languageCode,
  );

  setUp(() {
    source = FakeAttachmentSource();
    recorder = FakeAudioRecorder();
    player = FakeAudioPlayer();
    permissions = FakePermissionGateway();
    recognizer = FakeSpeechRecognizer();
    languageCode = 'en';
  });

  /// Runs [body] against a fresh bloc and always closes it, so a leaked
  /// subscription shows up as a test failure rather than a later mystery.
  Future<void> withBloc(Future<void> Function(AiComposerBloc bloc) body) async {
    final bloc = build();
    try {
      await body(bloc);
    } finally {
      await bloc.close();
    }
  }

  group('attachment picking', () {
    test('a successful pick stages the attachments as ready', () async {
      source.result = picked([imageFixture(), documentFixture()]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(2));
        expect(
          bloc.state.attachments.every((a) => a.isReady),
          isTrue,
        );
        expect(bloc.state.hasReadyAttachments, isTrue);
        expect(source.calls, [AiAttachmentIntent.gallery]);
      });
    });

    test('cancelling says nothing and stages nothing', () async {
      source.result = const AiAttachmentPickCancelled();

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(bloc.state.notice, isNull);
      });
    });

    test('a refusal notices without the settings path', () async {
      source.result = const AiAttachmentPickDenied(permanently: false);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.notice, isNotNull);
        expect(bloc.state.notice!.canOpenSettings, isFalse);
      });
    });

    test('a permanent refusal offers the settings path', () async {
      source.result = const AiAttachmentPickDenied(permanently: true);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.notice!.canOpenSettings, isTrue);
      });
    });

    test('a platform failure surfaces its key, never prose', () async {
      source.result = const AiAttachmentPickFailed(
        'ai_chat.attachment_pick_failed',
      );

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.document),
        );
        await pumpEventQueue();

        expect(bloc.state.notice!.messageKey, 'ai_chat.attachment_pick_failed');
      });
    });

    test('a second request while one is open is dropped', () async {
      source
        ..result = picked([imageFixture()])
        ..gate = Completer<void>();

      await withBloc((bloc) async {
        bloc
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
          )
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
          );
        await pumpEventQueue();

        expect(bloc.state.isPicking, isTrue);
        source.gate!.complete();
        await pumpEventQueue();

        // droppable(): the OS already had the foreground, so the second tap
        // never reaches the picker.
        expect(source.calls, [AiAttachmentIntent.gallery]);
      });
    });

    test('isPicking clears whatever the outcome', () async {
      source.result = const AiAttachmentPickFailed('ai_chat.x');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.isPicking, isFalse);
      });
    });
  });

  group('validation on the way in', () {
    test('an oversized file is rejected and not staged', () async {
      source.result = picked([
        imageFixture(sizeBytes: FileSizePolicy.maxBytes + 1),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(
          bloc.state.notice!.messageKey,
          AiAttachmentFailureKeys.tooLarge,
        );
      });
    });

    test('a mixed batch keeps the good ones and explains once', () async {
      source.result = picked([
        imageFixture(id: 'a'),
        imageFixture(id: 'b', sizeBytes: FileSizePolicy.maxBytes + 1),
        imageFixture(id: 'c'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments.map((a) => a.id), ['a', 'c']);
        expect(bloc.state.notice, isNotNull);
      });
    });

    test('a batch cannot overshoot the limit by arriving at once', () async {
      source.result = picked([
        for (var i = 0; i < rules.maxAttachments + 3; i++)
          imageFixture(id: 'a$i'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(rules.maxAttachments));
        expect(bloc.state.notice!.messageKey, AiAttachmentFailureKeys.tooMany);
      });
    });

    test('requesting more when already full never opens the picker', () async {
      source.result = picked([
        for (var i = 0; i < rules.maxAttachments; i++) imageFixture(id: 'a$i'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        expect(bloc.state.attachments, hasLength(rules.maxAttachments));

        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(source.calls, hasLength(1));
        expect(bloc.state.notice!.messageKey, AiAttachmentFailureKeys.tooMany);
      });
    });
  });

  group('removal and submission', () {
    test('removing drops the attachment', () async {
      source.result = picked([imageFixture(id: 'a'), imageFixture(id: 'b')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerAttachmentRemoved('a'));
        await pumpEventQueue();

        expect(bloc.state.attachments.map((a) => a.id), ['b']);
      });
    });

    test('removing an unknown id changes nothing', () async {
      source.result = picked([imageFixture(id: 'a')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerAttachmentRemoved('nope'));
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(1));
      });
    });

    test('removing a recording deletes its file', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);

        final id = bloc.state.attachments.single.id;
        bloc.add(AiComposerAttachmentRemoved(id));
        await pumpEventQueue();

        expect(recorder.discarded, ['/tmp/rec_1.m4a']);
      });
    });

    test('removing a picked image does NOT delete its file', () async {
      // Picker files live in the picker's own cache and are not ours to
      // remove. Deleting one could invalidate a cache another feature is using.
      source.result = picked([imageFixture(id: 'a')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerAttachmentRemoved('a'));
        await pumpEventQueue();

        expect(recorder.discarded, isEmpty);
      });
    });

    test('submitting clears everything without deleting the files', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);

        bloc.add(const AiComposerSubmitted());
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(bloc.state.recording, AiRecordingStatus.idle);
        // The file now belongs to a message in the conversation.
        expect(recorder.discarded, isEmpty);
      });
    });
  });

  group('notices', () {
    test('two identical failures both surface', () async {
      // The bug this guards: an equal notice would make listenWhen skip the
      // second one and the user would never be told twice.
      source.result = const AiAttachmentPickFailed('ai_chat.same');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        final first = bloc.state.notice!;

        bloc
          ..add(const AiComposerNoticeDismissed())
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
          );
        await pumpEventQueue();
        final second = bloc.state.notice!;

        expect(first.messageKey, second.messageKey);
        expect(first.id, isNot(second.id));
        expect(first, isNot(second));
      });
    });

    test('a notice can be cleared back to null', () async {
      source.result = const AiAttachmentPickFailed('ai_chat.x');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        expect(bloc.state.notice, isNotNull);

        bloc.add(const AiComposerNoticeDismissed());
        await pumpEventQueue();

        expect(bloc.state.notice, isNull);
      });
    });

    test('requesting settings opens them and clears the notice', () async {
      source.result = const AiAttachmentPickDenied(permanently: true);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerSettingsRequested());
        await pumpEventQueue();

        expect(permissions.settingsOpened, 1);
        expect(bloc.state.notice, isNull);
      });
    });
  });

  group('recording state machine', () {
    test('start asks for the microphone then records', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.recording);
        expect(recorder.startCount, 1);
        expect(recorder.lastMaxDuration, rules.maxRecordingDuration);
      });
    });

    test('a refused microphone stops at permissionDenied', () async {
      permissions.microphone = AiPermissionOutcome.denied;

      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.permissionDenied);
        expect(recorder.startCount, 0);
        expect(bloc.state.notice!.canOpenSettings, isFalse);
      });
    });

    test('a permanently refused microphone offers settings', () async {
      permissions.microphone = AiPermissionOutcome.permanentlyDenied;

      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.notice!.canOpenSettings, isTrue);
      });
    });

    test('no microphone hardware fails without starting', () async {
      recorder.available = false;

      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(recorder.startCount, 0);
      });
    });

    test('a recorder that throws on start fails cleanly', () async {
      recorder.throwOnStart = true;

      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(bloc.state.notice!.messageKey, 'ai_chat.recording_failed');
      });
    });

    test('stop produces a ready audio attachment in preview', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder, elapsed: const Duration(seconds: 9));

        expect(bloc.state.recording, AiRecordingStatus.preview);
        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.status, AiAttachmentStatus.ready);
        expect(take.duration, const Duration(seconds: 9));
        expect(take.localPath, '/tmp/rec_1.m4a');
        expect(take.waveform, hasLength(AiAudioAttachment.maxWaveformSamples));
      });
    });

    test('the saved waveform is the take, not the last reading', () async {
      // The regression. `_waveformSoFar` used to smear the most recent level
      // across all forty bars with a fixed pattern, so a take that started
      // loud and ended quiet drew the same flat shape as one that was silent
      // throughout — which is exactly what the reported screenshot showed.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        for (var i = 0; i < 20; i++) {
          await recorder.emitSample(0.9, Duration(milliseconds: i * 120));
        }
        for (var i = 20; i < 40; i++) {
          await recorder.emitSample(0, Duration(milliseconds: i * 120));
        }

        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.waveform, hasLength(AiAudioAttachment.maxWaveformSamples));

        final half = take.waveform.length ~/ 2;
        final opening = take.waveform.take(half);
        final ending = take.waveform.skip(half);

        expect(
          opening.reduce((a, b) => a > b ? a : b),
          greaterThan(0.8),
          reason: 'the loud opening must survive into the saved shape',
        );
        expect(
          ending.reduce((a, b) => a > b ? a : b),
          lessThan(0.2),
          reason: 'the quiet ending must not be repainted as loud',
        );
      });
    });

    test('a new take does not inherit the previous shape', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        for (var i = 0; i < 20; i++) {
          await recorder.emitSample(1, Duration(milliseconds: i * 120));
        }
        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        for (var i = 0; i < 20; i++) {
          await recorder.emitSample(0, Duration(milliseconds: i * 120));
        }
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.waveform.every((b) => b < 0.1), isTrue);
      });
    });

    test('a take that produced no file fails rather than staging', () async {
      recorder.stopPath = null;

      await withBloc((bloc) async {
        await _record(bloc, recorder);

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test('a recorder that throws on stop fails cleanly', () async {
      recorder.throwOnStop = true;

      await withBloc((bloc) async {
        await _record(bloc, recorder);

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test('cancel mid-take discards and returns to idle', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(recorder.cancelCount, 1);
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test('cancel from preview throws the finished take away', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        expect(bloc.state.attachments, hasLength(1));

        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
        expect(recorder.discarded, ['/tmp/rec_1.m4a']);
      });
    });

    test('stop while idle is a no-op', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(recorder.stopCount, 0);
        expect(bloc.state.recording, AiRecordingStatus.idle);
      });
    });

    test('a second start while recording is ignored', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(recorder.startCount, 1);
      });
    });

    test('reaching the duration cap stops the take by itself', () async {
      // No Timer: the recorder's own amplitude tick is the clock, and the
      // composer stops the take when that tick reaches the cap.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recorder.emitSample(0.5, rules.maxRecordingDuration);
        await pumpEventQueue();

        expect(recorder.stopCount, 1);
        expect(bloc.state.recording, AiRecordingStatus.preview);
      });
    });

    test('ticks past the cap do not stop a second time', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recorder.emitSample(0.5, rules.maxRecordingDuration);
        await pumpEventQueue();
        await recorder.emitSample(
          0.5,
          rules.maxRecordingDuration + const Duration(seconds: 5),
        );
        await pumpEventQueue();

        expect(recorder.stopCount, 1);
      });
    });

    test('a tick below the cap does not stop the take', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recorder.emitSample(
          0.5,
          rules.maxRecordingDuration - const Duration(seconds: 1),
        );
        await pumpEventQueue();

        expect(recorder.stopCount, 0);
        expect(bloc.state.recording, AiRecordingStatus.recording);
      });
    });

    test('recording is refused when the message is already full', () async {
      source.result = picked([
        for (var i = 0; i < rules.maxAttachments; i++) imageFixture(id: 'a$i'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(recorder.startCount, 0);
        expect(bloc.state.notice!.messageKey, AiAttachmentFailureKeys.tooMany);
      });
    });
  });

  group('interruption', () {
    test('an interruption ends the take and explains', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recorder.emitAbort(AiRecordingAbort.interrupted);
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(
          bloc.state.notice!.messageKey,
          'ai_chat.recording_interrupted',
        );
        expect(recorder.cancelCount, 1);
      });
    });

    test('a platform failure mid-take is reported', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recorder.emitAbort(AiRecordingAbort.failed);
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.failed);
        expect(bloc.state.notice!.messageKey, 'ai_chat.recording_failed');
      });
    });

    test('an abort while idle changes nothing', () async {
      await withBloc((bloc) async {
        await recorder.emitAbort(AiRecordingAbort.interrupted);
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.notice, isNull);
      });
    });
  });

  group('the hot path stays off bloc state', () {
    test('a live sample updates the controller and emits NO state', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        final states = <AiComposerState>[];
        final sub = bloc.stream.listen(states.add);

        for (var i = 1; i <= 20; i++) {
          await recorder.emitSample(i / 20, Duration(milliseconds: i * 100));
        }

        expect(
          states,
          isEmpty,
          reason: '20 microphone ticks must not emit a single bloc state',
        );
        expect(bloc.recordingLevel.value.level, closeTo(1, 0.001));
        // The meter needs a series, and it must arrive on the same hot path —
        // still without a single bloc emission.
        expect(
          bloc.recordingLevel.history,
          hasLength(LevelHistory.defaultLength),
        );
        expect(bloc.recordingLevel.history.last, closeTo(1, 0.001));
        expect(
          bloc.recordingLevel.value.elapsed,
          const Duration(milliseconds: 2000),
        );

        await sub.cancel();
      });
    });

    test(
      'playback progress updates the controller and emits NO state',
      () async {
        await withBloc((bloc) async {
          await _record(bloc, recorder);
          final take = bloc.state.attachments.single as AiAudioAttachment;

          bloc.add(AiComposerPlaybackToggled(take));
          await pumpEventQueue();

          final states = <AiComposerState>[];
          final sub = bloc.stream.listen(states.add);

          for (var i = 1; i <= 10; i++) {
            await player.emitProgress(
              AiPlaybackProgress(
                position: Duration(milliseconds: i * 200),
                duration: const Duration(seconds: 2),
                isPlaying: true,
              ),
            );
          }

          expect(states, isEmpty);
          expect(bloc.playback.value.progress.fraction, closeTo(1, 0.001));
          expect(bloc.playback.value.isPlaying(take.id), isTrue);

          await sub.cancel();
        });
      },
    );

    test('the level resets when a take ends', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.8, const Duration(seconds: 3));

        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.recordingLevel.value, AiRecordingSample.zero);
      });
    });
  });

  group('playback', () {
    test('toggling plays, then pauses, then resumes', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();
        expect(player.played, [take.id]);

        await player.emitProgress(
          const AiPlaybackProgress(
            position: Duration(seconds: 1),
            duration: Duration(seconds: 9),
            isPlaying: true,
          ),
        );

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();
        expect(player.pauseCount, 1);

        // A real player reports the pause on its own stream, and the bloc
        // reads playing/paused from there rather than tracking it itself —
        // which is why the fake has to say so too.
        await player.emitProgress(
          const AiPlaybackProgress(
            position: Duration(seconds: 1),
            duration: Duration(seconds: 9),
            isPlaying: false,
          ),
        );

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();
        expect(player.resumeCount, 1);
      });
    });

    test('a voice note that is no longer staged still plays', () async {
      // The regression. Submitting clears the composer, so a sent voice note
      // is not in `state.attachments` any more — but its bubble still has a
      // play button, and one player serves both halves of the screen. Looking
      // the id up in the composer's own list made that button inert, which is
      // exactly what happened on device.
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;

        bloc.add(const AiComposerSubmitted());
        await pumpEventQueue();
        expect(bloc.state.attachments, isEmpty);

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        expect(player.playedPaths, contains(take.localPath));
        expect(bloc.playback.value.isLoaded(take.id), isTrue);
      });
    });

    test('a player that cannot open the file notices and unloads', () async {
      player.throwOnPlay = true;

      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        expect(bloc.state.notice!.messageKey, 'ai_chat.playback_failed');
        expect(bloc.playback.value.attachmentId, isNull);
      });
    });

    test('a stale tick from a stopped player is ignored', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        // The player moved on; a late frame must not drive the loaded row.
        await player.stop();
        await player.emitProgress(
          const AiPlaybackProgress(
            position: Duration(seconds: 5),
            duration: Duration(seconds: 9),
            isPlaying: true,
          ),
        );

        expect(bloc.playback.value.progress, AiPlaybackProgress.idle);
      });
    });

    test('removing the playing attachment stops the player', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;

        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        bloc.add(AiComposerAttachmentRemoved(take.id));
        await pumpEventQueue();

        expect(player.stopCount, greaterThanOrEqualTo(1));
        expect(bloc.playback.value.attachmentId, isNull);
      });
    });
  });

  group('canSend', () {
    test('text alone is enough', () {
      expect(const AiComposerState().canSend('hello'), isTrue);
    });

    test('whitespace alone is not', () {
      expect(const AiComposerState().canSend('   '), isFalse);
    });

    test('an attachment alone is enough', () {
      final state = AiComposerState(
        attachments: [imageFixture(status: AiAttachmentStatus.ready)],
      );

      expect(state.canSend(''), isTrue);
    });

    test('a still-preparing attachment blocks sending', () {
      final state = AiComposerState(
        attachments: [imageFixture(status: AiAttachmentStatus.processing)],
      );

      expect(state.canSend('hi'), isFalse);
    });

    test('recording blocks sending', () {
      const state = AiComposerState(recording: AiRecordingStatus.recording);

      expect(state.canSend('hi'), isFalse);
    });

    test('a preview take does not block sending', () {
      const state = AiComposerState(recording: AiRecordingStatus.preview);

      expect(state.canSend('hi'), isTrue);
    });
  });

  group('disposal', () {
    test(
      'close releases the recorder, the player and both controllers',
      () async {
        final bloc = build();
        await bloc.close();

        expect(recorder.disposeCount, 1);
        expect(player.disposeCount, 1);
      },
    );

    test('close deletes recordings that were never sent', () async {
      final bloc = build();
      await _record(bloc, recorder);
      await bloc.close();

      expect(recorder.discarded, ['/tmp/rec_1.m4a']);
    });

    test('close while recording still tears down', () async {
      final bloc = build()..add(const AiComposerRecordingStarted());
      await pumpEventQueue();

      await bloc.close();

      expect(recorder.disposeCount, 1);
    });

    test('closing twice is safe', () async {
      final bloc = build();
      await bloc.close();
      await bloc.close();

      expect(recorder.disposeCount, 1);
    });
  });

  group('dictation', () {
    /// Drives the bloc into `listening`.
    Future<void> startSpeech(AiComposerBloc bloc) async {
      bloc.add(const AiComposerSpeechStarted());
      await pumpEventQueue();
    }

    test('it asks for both grants, then listens', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.listening);
        expect(recognizer.startCount, 1);
      });
    });

    test('a refused microphone never reaches the recogniser', () async {
      permissions.microphone = AiPermissionOutcome.denied;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_denied');
        expect(bloc.state.notice!.canOpenSettings, isFalse);
        expect(recognizer.startCount, 0);
      });
    });

    test('a refused speech grant is its own path', () async {
      // iOS asks twice. Allowing the microphone and refusing recognition is a
      // real state, and it must not read as a microphone problem.
      permissions.speechRecognition = AiPermissionOutcome.permanentlyDenied;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(
          bloc.state.notice!.messageKey,
          'ai_chat.speech_denied_permanently',
        );
        expect(bloc.state.notice!.canOpenSettings, isTrue);
        expect(recognizer.startCount, 0);
      });
    });

    test('an unavailable recogniser fails before listening', () async {
      recognizer.available = false;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_unavailable');
        expect(recognizer.startCount, 0);
      });
    });

    test('a recogniser that throws is reported, not swallowed', () async {
      recognizer.throwOnStart = true;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_failed');
      });
    });

    test('the app language chooses the recognition locale', () async {
      languageCode = 'ar';

      await withBloc((bloc) async {
        await startSpeech(bloc);
        expect(recognizer.startedLocales, ['ar-AE']);
      });
    });

    test('a language the device lacks falls back to its default', () async {
      languageCode = 'ar';
      recognizer.locales = ['en-US'];

      await withBloc((bloc) async {
        await startSpeech(bloc);

        // `null` = let the device decide. Dictating in the wrong language is a
        // better outcome than a button that refuses to work.
        expect(recognizer.startedLocales, [null]);
        expect(bloc.state.speech, AiSpeechStatus.listening);
      });
    });

    test('partial results reach the controller and emit NO state', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);

        final states = <AiComposerState>[];
        final sub = bloc.stream.listen(states.add);

        for (final word in ['book', 'book a', 'book a table']) {
          await recognizer.emitTranscript(word);
        }

        // The load-bearing assertion of the whole hot path: if these emitted,
        // the message list above the composer would rebuild on every word.
        expect(
          states,
          isEmpty,
          reason: 'partial transcripts must not emit composer state',
        );
        expect(bloc.transcript.value.text, 'book a table');
        expect(bloc.transcript.value.isFinal, isFalse);

        await sub.cancel();
      });
    });

    test('stopping finalises and leaves the text in place', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('book a table', isFinal: true);

        bloc.add(const AiComposerSpeechStopped());
        await pumpEventQueue();

        expect(recognizer.stopCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.completed);
        // Still there — it is ordinary editable composer text now.
        expect(bloc.transcript.value.text, 'book a table');
      });
    });

    test('cancelling throws the words away', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('never mind');

        bloc.add(const AiComposerSpeechCancelled());
        await pumpEventQueue();

        expect(recognizer.cancelCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('a recogniser that stops itself moves the state machine', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('a short phrase', isFinal: true);

        // Nobody pressed anything: the platform ended the phrase after a
        // pause. The composer must follow rather than keep claiming to listen.
        await recognizer.emitListening(value: false);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.completed);
      });
    });

    test('hearing nothing is not an error banner', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitFailure(AiSpeechFailure.noMatch);
        await pumpEventQueue();

        // Pressing the button and not speaking is normal. It just goes quiet.
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.notice, isNull);
      });
    });

    test('a real failure surfaces its own message', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_network');
      });
    });

    test('a failure arriving after a cancel is ignored', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        bloc.add(const AiComposerSpeechCancelled());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.idle);

        // The plugin reports an error on its way down. Nobody is waiting on
        // this dictation any more, so it must not raise a banner.
        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.notice, isNull);
      });
    });

    test('sending clears dictation along with everything else', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('send this', isFinal: true);
        bloc.add(const AiComposerSpeechStopped());
        await pumpEventQueue();

        bloc.add(const AiComposerSubmitted());
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('closing releases the recogniser', () async {
      final bloc = build();
      await bloc.close();

      expect(recognizer.disposeCount, 1);
    });
  });

  group('one capability holds the microphone at a time', () {
    test('dictation is refused while recording', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        expect(bloc.state.recording, AiRecordingStatus.recording);

        // The take has the recogniser transcribing for it, so the count is
        // already non-zero. What must not happen is a *second*, dictation-owned
        // session on top of it.
        final duringTake = recognizer.startCount;

        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        expect(recognizer.startCount, duringTake);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.recording, AiRecordingStatus.recording);
      });
    });

    test('recording is refused while dictating', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.listening);

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(recorder.startCount, 0);
        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.speech, AiSpeechStatus.listening);
      });
    });

    test('dictation stops playback first', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;
        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        // A voice note playing into the microphone would be transcribed.
        expect(player.stopCount, greaterThanOrEqualTo(1));
        expect(bloc.playback.value.attachmentId, isNull);
      });
    });

    test('sending cannot happen mid-phrase', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        expect(bloc.state.canSend('half a sentence'), isFalse);
      });
    });

    test('an explicit playback stop releases the player', () async {
      // What the page dispatches before opening live voice, so the chat's
      // player is not holding the speaker under the voice route's session.
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;
        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        bloc.add(const AiComposerPlaybackStopped());
        await pumpEventQueue();

        expect(player.stopCount, greaterThanOrEqualTo(1));
        expect(bloc.playback.value.attachmentId, isNull);
      });
    });
  });

  group('leaving the foreground', () {
    test('it cancels dictation', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('mid sentence');

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(recognizer.cancelCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('it aborts a recording and releases the partial file', () async {
      // The regression this hardening exists for: the activity finishes, the
      // widget tree is never torn down, and a half-recorded take used to be
      // left in the cache forever. `cancel` is the recorder's stop-release-
      // and-delete path.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.7, const Duration(seconds: 3));

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(recorder.cancelCount, 1);
        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.recordingLevel.value, AiRecordingSample.zero);
      });
    });

    test('it stops playback', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single as AiAudioAttachment;
        bloc.add(AiComposerPlaybackToggled(take));
        await pumpEventQueue();

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(bloc.playback.value.attachmentId, isNull);
      });
    });

    test('it is harmless when nothing is running', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(bloc.state, const AiComposerState());
        expect(recorder.cancelCount, 0);
        expect(recognizer.cancelCount, 0);
      });
    });

    test('a take abandoned this way does not haunt the next one', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(1, const Duration(seconds: 2));
        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0, const Duration(seconds: 1));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.waveform.every((b) => b < 0.1), isTrue);
      });
    });
  });

  group('a voice note carries its own transcript', () {
    test('the take runs the recogniser alongside the recorder', () async {
      // The one thing that makes a voice note one message: the words are
      // captured while the audio is, because the plugin cannot transcribe a
      // finished file.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(recorder.startCount, 1);
        expect(recognizer.startCount, 1);
      });
    });

    test('what was heard lands on the attachment', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('book me a plumber', isFinal: true);
        await recorder.emitSample(0.6, const Duration(seconds: 5));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.transcript, 'book me a plumber');
      });
    });

    test('the audio is untouched by the transcript', () async {
      // The recording is the deliverable; the transcript rides along.
      // Duration, waveform and path must be what they were before.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('some words', isFinal: true);
        await recorder.emitSample(0.6, const Duration(seconds: 5));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.localPath, recorder.stopPath);
        expect(take.duration, const Duration(seconds: 5));
        expect(take.waveform, hasLength(AiAudioAttachment.maxWaveformSamples));
        expect(take.status, AiAttachmentStatus.ready);
      });
    });

    test('speech state is never entered by a take', () async {
      // The load-bearing invariant. `state.speech` describes the dictation
      // capability the user can see and start; a voice note borrowing the
      // recogniser must leave every check built on it — the mutual-exclusion
      // guards, `canSend`, which bar the composer shows — as it found them.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.idle);

        await recognizer.emitTranscript('mid take');
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.idle);

        await recorder.emitSample(0.6, const Duration(seconds: 5));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.idle);
      });
    });

    test('a take never writes the composer text field', () async {
      // Dictation puts words in the field; a voice note must not, or the user
      // would find their recording typed out underneath it.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('spoken into the note');

        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('a paused recogniser restarts, keeping both halves', () async {
      // It is built for phrases and settles after its own pause, so a take
      // that spans a moment of thought spans several sessions.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('book me a plumber', isFinal: true);
        await recognizer.emitListening(value: false);
        await pumpEventQueue();

        expect(recognizer.startCount, 2);

        await recognizer.emitTranscript('for tomorrow', isFinal: true);
        await recorder.emitSample(0.6, const Duration(seconds: 5));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.transcript, 'book me a plumber for tomorrow');
      });
    });
  });

  group('a missing transcript is not a failure', () {
    test('an unavailable recogniser still yields a recording', () async {
      await withBloc((bloc) async {
        recognizer.available = false;

        await _record(bloc, recorder);

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.transcript, isEmpty);
        expect(take.localPath, recorder.stopPath);
      });
    });

    test('an unavailable recogniser raises no notice', () async {
      // The user asked for a voice note, not for dictation. Blaming them for a
      // capability they never invoked would be noise.
      await withBloc((bloc) async {
        recognizer.available = false;

        await _record(bloc, recorder);

        expect(bloc.state.notice, isNull);
        expect(bloc.state.speech, AiSpeechStatus.idle);
      });
    });

    test('a recogniser that will not start still yields a recording', () async {
      await withBloc((bloc) async {
        recognizer.throwOnStart = true;

        await _record(bloc, recorder);

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.transcript, isEmpty);
        expect(bloc.state.notice, isNull);
      });
    });

    test('a recogniser failure mid-take is silent', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.notice, isNull);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.recording, AiRecordingStatus.recording);
      });
    });
  });

  group('a discarded take discards its words', () {
    test('cancelling releases the recogniser and forgets it', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('never sent', isFinal: true);

        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        expect(recognizer.cancelCount, greaterThanOrEqualTo(1));
        expect(bloc.takeTranscript.text, isEmpty);
      });
    });

    test('backgrounding releases the recogniser', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('never sent', isFinal: true);

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(recognizer.cancelCount, greaterThanOrEqualTo(1));
        expect(bloc.takeTranscript.text, isEmpty);
      });
    });

    test('an interruption releases the recogniser', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('never sent', isFinal: true);

        await recorder.emitAbort(AiRecordingAbort.interrupted);
        await pumpEventQueue();

        expect(bloc.takeTranscript.text, isEmpty);
      });
    });

    test('a new take does not inherit the previous words', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('the first take', isFinal: true);
        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('the second take', isFinal: true);
        await recorder.emitSample(0.6, const Duration(seconds: 5));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        final take = bloc.state.attachments.single as AiAudioAttachment;
        expect(take.transcript, 'the second take');
      });
    });
  });

  group('dictation is unaffected', () {
    test('it still writes the composer text field', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('typed by voice');

        expect(bloc.transcript.value.text, 'typed by voice');
        expect(bloc.takeTranscript.text, isEmpty);
      });
    });

    test('its failures still raise a notice', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice?.messageKey, 'ai_chat.speech_network');
      });
    });

    test('the recogniser ending still completes the phrase', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitListening(value: true);
        await pumpEventQueue();

        await recognizer.emitListening(value: false);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.completed);
      });
    });
  });

  group('locking a take', () {
    test('a held take locks and keeps recording', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.lockedRecording);
        // Nothing is asked of the recorder: the microphone was already open
        // and stays open. Only the way the take *ends* changed.
        expect(recorder.stopCount, 0);
        expect(recorder.cancelCount, 0);
        expect(recorder.startCount, 1);
      });
    });

    test('a locked take is still capturing', () async {
      // Every guard in this bloc is built on `isCapturing`. If locking fell
      // out of it, the duration cap, backgrounding cleanup and dictation's
      // mutual exclusion would all quietly stop covering a locked take.
      expect(AiRecordingStatus.lockedRecording.isCapturing, isTrue);
      expect(AiRecordingStatus.lockedRecording.occupiesComposer, isTrue);
      expect(AiRecordingStatus.lockedRecording.showsRecordingRow, isTrue);
      expect(AiRecordingStatus.lockedRecording.blocksSend, isTrue);
    });

    test('locking is ignored from every status but recording', () async {
      for (final status in [
        AiRecordingStatus.idle,
        AiRecordingStatus.permissionDenied,
        AiRecordingStatus.failed,
      ]) {
        await withBloc((bloc) async {
          // Reached without a take, so the lock has nothing to act on.
          if (status == AiRecordingStatus.permissionDenied) {
            permissions.microphone = AiPermissionOutcome.denied;
            bloc.add(const AiComposerRecordingStarted());
            await pumpEventQueue();
          }

          bloc.add(const AiComposerRecordingLocked());
          await pumpEventQueue();

          expect(
            bloc.state.recording,
            isNot(AiRecordingStatus.lockedRecording),
          );
        });
        permissions.microphone = AiPermissionOutcome.granted;
      }
    });

    test('an explicit stop ends a locked take', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();

        await recorder.emitSample(0.7, const Duration(seconds: 4));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.preview);
        expect(bloc.state.attachments.single, isA<AiAudioAttachment>());
        expect(recorder.stopCount, 1);
      });
    });

    test('deleting a locked take discards the file', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();
        await recorder.emitSample(0.7, const Duration(seconds: 4));

        bloc.add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
        expect(recorder.cancelCount, 1);
        expect(recorder.stopCount, 0);
      });
    });

    test('backgrounding a locked take cleans it up', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();
        await recorder.emitSample(0.7, const Duration(seconds: 4));

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(recorder.cancelCount, 1);
      });
    });

    test('a locked take still stops itself at the duration cap', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();

        await recorder.emitSample(0.5, rules.maxRecordingDuration);
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.preview);
        expect(recorder.stopCount, 1);
      });
    });

    test('autoLock starts a take already hands-free', () async {
      // The accessibility path. It is a flag on the start rather than a
      // following lock event because `sequential()` orders events only within
      // one type, so two events would race the permission round-trip.
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted(autoLock: true));
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.lockedRecording);
      });
    });
  });

  group('a take that is too short is a mis-tap, not a message', () {
    test('it is discarded rather than attached', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.6, const Duration(milliseconds: 200));

        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
        // Cancelled, not stopped: `stop()` on a take this brief returns either
        // nothing or an unplayable blip, and cancel is what deletes the file.
        expect(recorder.cancelCount, 1);
        expect(recorder.stopCount, 0);
      });
    });

    test('it coaches rather than blames', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.6, const Duration(milliseconds: 200));
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.state.notice?.messageKey, 'ai_chat.recording_too_short');
        expect(bloc.state.notice?.tone, AiNoticeTone.info);
      });
    });

    test('a take at the threshold is kept', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.6, rules.minRecordingDuration);
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.preview);
        expect(bloc.state.attachments, hasLength(1));
      });
    });

    test('a tap on the microphone starts nothing at all', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingHintRequested());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(recorder.startCount, 0);
        expect(bloc.state.notice?.messageKey, 'ai_chat.record_hold_hint');
        expect(bloc.state.notice?.tone, AiNoticeTone.info);
      });
    });
  });

  group('a release that beats the take it belongs to', () {
    // `sequential()` orders events only within one event type — `Bloc.on<E>`
    // filters the stream by `E` before applying the transformer — so a stop
    // does NOT queue behind a start. Every test here would pass vacuously if
    // it did, and every one of them fails without `_startInFlight`.

    test('releasing during the permission prompt starts nothing', () async {
      await withBloc((bloc) async {
        permissions.microphoneGate = Completer<void>();
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        expect(bloc.state.recording, AiRecordingStatus.requestingPermission);

        // The finger comes up while the OS dialog still has the pointer.
        bloc.add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        permissions.microphoneGate!.complete();
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        // The microphone was never opened, so there is no session to release
        // and no partial file to delete.
        expect(recorder.startCount, 0);
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test(
      'the gesture being cancelled during the prompt starts nothing',
      () async {
        // The shape of the first-ever permission dialog: it steals the pointer,
        // the recognizer reports a cancellation, and the grant arrives after.
        await withBloc((bloc) async {
          permissions.microphoneGate = Completer<void>();
          bloc.add(const AiComposerRecordingStarted());
          await pumpEventQueue();

          bloc.add(const AiComposerRecordingCancelled());
          await pumpEventQueue();

          permissions.microphoneGate!.complete();
          await pumpEventQueue();

          expect(bloc.state.recording, AiRecordingStatus.idle);
          expect(recorder.startCount, 0);
          expect(bloc.state.notice, isNull);
        });
      },
    );

    test('a cancel supersedes a stop latched before it', () async {
      await withBloc((bloc) async {
        permissions.microphoneGate = Completer<void>();
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc
          ..add(const AiComposerRecordingStopped())
          ..add(const AiComposerRecordingCancelled());
        await pumpEventQueue();

        permissions.microphoneGate!.complete();
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test('backgrounding during the prompt starts nothing', () async {
      await withBloc((bloc) async {
        permissions.microphoneGate = Completer<void>();
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        permissions.microphoneGate!.complete();
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(recorder.startCount, 0);
      });
    });

    test('a lock during the prompt is honoured, not dropped', () async {
      // A fast upward flick can beat a platform-channel permission round-trip
      // on a cold device. Dropping it would leave the user's finger coming up
      // onto an unlocked take after they watched the lock affordance engage.
      await withBloc((bloc) async {
        permissions.microphoneGate = Completer<void>();
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        bloc.add(const AiComposerRecordingLocked());
        await pumpEventQueue();

        permissions.microphoneGate!.complete();
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.lockedRecording);
      });
    });

    test('a cancel and a stop together leave one clean outcome', () async {
      // The cancel-drag that also ends in a release. Two terminal intents,
      // different event types, so they run concurrently — without the release
      // guard the stop calls `stop()` on a recorder the cancel already tore
      // down and a deliberate discard reports "nothing was recorded".
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();
        await recorder.emitSample(0.6, const Duration(seconds: 3));

        bloc
          ..add(const AiComposerRecordingCancelled())
          ..add(const AiComposerRecordingStopped());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
        expect(recorder.stopCount, 0);
        expect(bloc.state.notice, isNull);
      });
    });
  });

  group('what the composer draws for a take', () {
    test(
      'a previewed take is the preview take, and is not in the strip',
      () async {
        await withBloc((bloc) async {
          await _record(bloc, recorder);

          final take = bloc.state.previewTake;
          expect(take, isNotNull);
          expect(bloc.state.attachments, contains(take));
          // The preview row draws it; the strip must not draw it again.
          expect(bloc.state.stripAttachments, isEmpty);
        });
      },
    );

    test('other attachments still reach the strip beside a preview', () async {
      await withBloc((bloc) async {
        source.result = AiAttachmentsPicked([
          documentFixture(),
        ]);
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.document),
        );
        await pumpEventQueue();

        await _record(bloc, recorder);

        expect(bloc.state.attachments, hasLength(2));
        expect(bloc.state.stripAttachments, hasLength(1));
        expect(bloc.state.stripAttachments.single, isA<AiDocumentAttachment>());
      });
    });

    test('there is no preview take outside preview', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.previewTake, isNull);
      });
    });

    test('removing the previewed take returns the composer to idle', () async {
      await withBloc((bloc) async {
        await _record(bloc, recorder);
        final take = bloc.state.attachments.single;

        bloc.add(AiComposerAttachmentRemoved(take.id));
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.idle);
        expect(bloc.state.attachments, isEmpty);
        expect(recorder.discarded, contains(take.localPath));
      });
    });

    test('a take under preview blocks a second one from starting', () async {
      // What makes the removal above unambiguous: while a take is previewed
      // there can never be a *live* recorder for a removal to strand.
      await withBloc((bloc) async {
        await _record(bloc, recorder);

        bloc.add(const AiComposerRecordingStarted());
        await pumpEventQueue();

        expect(bloc.state.recording, AiRecordingStatus.preview);
        expect(recorder.startCount, 1);
      });
    });
  });

  group('canSend across a take', () {
    test('every state before a take exists blocks, preview does not', () {
      const withText = 'hello';
      for (final status in AiRecordingStatus.values) {
        final state = AiComposerState(recording: status);
        expect(
          state.canSend(withText),
          !status.blocksSend,
          reason: 'canSend disagreed with blocksSend for $status',
        );
      }

      // Spelled out, so the intent survives a change to `blocksSend`.
      expect(
        const AiComposerState(
          recording: AiRecordingStatus.lockedRecording,
        ).canSend(withText),
        isFalse,
      );
      expect(
        const AiComposerState(
          recording: AiRecordingStatus.encoding,
        ).canSend(withText),
        isFalse,
      );
      expect(
        const AiComposerState(
          recording: AiRecordingStatus.preview,
        ).canSend(withText),
        isTrue,
      );
    });
  });
}

/// Drives one full take to `preview` and leaves it staged.
Future<void> _record(
  AiComposerBloc bloc,
  FakeAudioRecorder recorder, {
  Duration elapsed = const Duration(seconds: 5),
}) async {
  bloc.add(const AiComposerRecordingStarted());
  await pumpEventQueue();
  await recorder.emitSample(0.6, elapsed);
  bloc.add(const AiComposerRecordingStopped());
  await pumpEventQueue();
}
