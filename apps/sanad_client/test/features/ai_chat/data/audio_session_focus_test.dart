import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/record_voice_capture.dart';

/// The self-interruption regression.
///
/// Capture used to die roughly 100 ms after it started, with the platform
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
    test('the live-voice capture config leaves focus to the session', () {
      // The one line that separates working capture from self-cancelling
      // capture. `record` defaults to `AudioInterruptionMode.pause`, which
      // makes its Android recorder request focus of its own.
      //
      // This is now the *only* capture config in the app: AI Chat records no
      // audio, so the live-voice session is the sole `record` client.
      expect(
        RecordVoiceCapture.captureConfig.audioInterruption,
        AudioInterruptionMode.none,
      );
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
