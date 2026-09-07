import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/record_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/record_voice_capture.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';

/// The self-interruption regression.
///
/// A take used to die roughly 100 ms after it started, with the platform
/// logging `onAudioFocusChange(-1)` in between. Nothing external was
/// interrupting it: `AudioSessionManager` took `AUDIOFOCUS_GAIN`, then
/// `record` — which manages focus itself by default — took `AUDIOFOCUS_GAIN`
/// again with a listener of its own. Android's focus stack is keyed by
/// listener rather than by process, so the second request evicted the first
/// and delivered it a loss, which arrived back through
/// `interruptionEventStream` indistinguishable from a phone call.
///
/// Every assertion here is a pure value check: the decisions that used to be
/// unreachable behind a plugin were lifted into constants and static
/// functions, so the fix is verifiable with no microphone and no device.
void main() {
  group('single audio-focus owner', () {
    test('the recording config leaves focus entirely to the session', () {
      // The one line that separates a working recorder from a self-cancelling
      // one. `record` defaults to `AudioInterruptionMode.pause`, which makes
      // its Android recorder request focus of its own.
      expect(
        RecordAudioRecorder.recordingConfig.audioInterruption,
        AudioInterruptionMode.none,
      );
    });

    test('the live-voice capture config does too', () {
      expect(
        RecordVoiceCapture.captureConfig.audioInterruption,
        AudioInterruptionMode.none,
      );
    });

    test('the recording config still fits inside the size ceiling', () {
      // Guarded alongside the focus setting because both live in the same
      // constant now: a future edit that reaches for one must not disturb the
      // other. 32 kbps mono is ~4 KB/s, so five minutes is ~1.2 MB.
      const config = RecordAudioRecorder.recordingConfig;
      expect(config.encoder, AudioEncoder.aacLc);
      expect(config.bitRate, 32000);
      expect(config.numChannels, 1);

      const maxDuration = Duration(minutes: 5);
      final bytes = config.bitRate / 8 * maxDuration.inSeconds;
      expect(bytes, lessThan(5 * 1024 * 1024));
    });
  });

  group('AudioSessionManager.mapInterruption', () {
    test('a beginning pause interruption is a real interruption', () {
      expect(
        AudioSessionManager.mapInterruption(
          AudioInterruptionEvent(true, AudioInterruptionType.pause),
        ),
        AudioSessionEvent.interrupted,
      );
    });

    test('an unknown beginning interruption is treated as a real one', () {
      // `AUDIOFOCUS_LOSS` maps to `unknown`. Now that we are the only focus
      // client, a loss really is somebody else taking the audio path.
      expect(
        AudioSessionManager.mapInterruption(
          AudioInterruptionEvent(true, AudioInterruptionType.unknown),
        ),
        AudioSessionEvent.interrupted,
      );
    });

    test('a duck request is NOT an interruption', () {
      expect(
        AudioSessionManager.mapInterruption(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        ),
        AudioSessionEvent.ducked,
      );
    });

    test('an ending interruption resumes, whatever its type', () {
      for (final type in AudioInterruptionType.values) {
        expect(
          AudioSessionManager.mapInterruption(
            AudioInterruptionEvent(false, type),
          ),
          AudioSessionEvent.resumed,
          reason: 'ending a $type interruption should resume',
        );
      }
    });
  });

  group('RecordAudioRecorder.abortFor', () {
    test('only a real interruption ends a take', () {
      expect(
        RecordAudioRecorder.abortFor(AudioSessionEvent.interrupted),
        AiRecordingAbort.interrupted,
      );
    });

    test('ducking does not end a take', () {
      expect(RecordAudioRecorder.abortFor(AudioSessionEvent.ducked), isNull);
    });

    test('unplugging headphones does not end a take', () {
      // `ACTION_AUDIO_BECOMING_NOISY` is an output-route event. Throwing away
      // a voice note because the user pulled their earbuds out is a defect.
      expect(
        RecordAudioRecorder.abortFor(AudioSessionEvent.becameNoisy),
        isNull,
      );
    });

    test('a resumed session does not reopen the microphone', () {
      expect(RecordAudioRecorder.abortFor(AudioSessionEvent.resumed), isNull);
    });

    test('every session event is classified', () {
      for (final event in AudioSessionEvent.values) {
        expect(
          () => RecordAudioRecorder.abortFor(event),
          returnsNormally,
          reason: '$event must have a classification',
        );
      }
    });
  });

  group('session configuration is chosen for the job', () {
    test('recording uses a capture-capable category', () {
      // `playback` — what the previous single configuration used — physically
      // forbids capture on iOS, so a take could never have started there.
      expect(
        AudioSessionManager.recordingConfiguration.avAudioSessionCategory,
        AVAudioSessionCategory.playAndRecord,
      );
    });

    test('recording does not rewrite a duck into a pause', () {
      // With `androidWillPauseWhenDucked: true`, `audio_session` reports a
      // duck request as a *pause* interruption — which would end a take on
      // every incoming notification.
      expect(
        AudioSessionManager.recordingConfiguration.androidWillPauseWhenDucked,
        isFalse,
      );
    });

    test('recording asks for exclusive transient focus', () {
      expect(
        AudioSessionManager.recordingConfiguration.androidAudioFocusGainType,
        AndroidAudioFocusGainType.gainTransientExclusive,
      );
      expect(
        AudioSessionManager
            .recordingConfiguration
            .androidAudioAttributes
            ?.usage,
        AndroidAudioUsage.voiceCommunication,
      );
    });

    test('playback and recording are genuinely different configurations', () {
      expect(
        AudioSessionManager.playbackConfiguration.avAudioSessionCategory,
        isNot(
          AudioSessionManager.recordingConfiguration.avAudioSessionCategory,
        ),
      );
    });

    test('a fresh manager has configured nothing yet', () {
      // The category is decided per activation, not once on first use — which
      // is what used to let whichever of recording or playback happened first
      // silently pick the category for the whole visit.
      expect(AudioSessionManager().configuredMode, isNull);
    });
  });
}
