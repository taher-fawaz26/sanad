import 'dart:async';

import 'package:audio_session/audio_session.dart';

/// What the session is being taken for.
///
/// The category has to be decided *before* focus is requested: on iOS a
/// `playback` category physically forbids capture, so activating a
/// playback-shaped session and then opening the microphone fails at the
/// platform layer rather than at ours.
enum AudioSessionMode {
  /// A live-voice turn. Capture must be permitted.
  recording,

  /// Playing the assistant's reply back.
  playback,
}

/// What the platform did to our audio.
enum AudioSessionEvent {
  /// A call, an alarm, another app — audio must stop now.
  interrupted,

  /// Another app asked to be heard over us without stopping us.
  ///
  /// Distinct from [interrupted] on purpose. Ducking is a *mixing* request:
  /// playback should drop its volume, and capture is not affected at all.
  /// Treating it as an interruption is what would end a live-voice turn
  /// because a notification chimed.
  ducked,

  /// The interruption ended and audio may resume.
  resumed,

  /// Headphones were unplugged or a Bluetooth device disconnected.
  ///
  /// An *output* route event (`ACTION_AUDIO_BECOMING_NOISY`): it says playback
  /// is about to blast out of the speaker. It says nothing about capture.
  becameNoisy,
}

/// Owns audio focus and route changes for the feature's live-voice session.
///
/// The only file that names `audio_session`. It exists because a duplex voice
/// session has to cooperate with the rest of the phone: a call arriving
/// mid-turn must end that turn, and unplugging headphones while the assistant
/// is speaking must not blast audio out of the speaker.
///
/// Live voice is its only client. The chat composer holds no audio session at
/// all — its microphone capability is speech recognition, and the platform's
/// recogniser manages its own session (see `SpeechToTextRecognizer`).
///
/// ## One focus owner, deliberately
///
/// This class is the app's **single** audio-focus client, and everything that
/// opens the microphone must let it stay that way. Android's focus stack is
/// keyed by listener, not by process: a second `AUDIOFOCUS_GAIN` request from
/// the same app evicts the first one and delivers it `AUDIOFOCUS_LOSS`. So a
/// capture plugin that quietly requests focus of its own does not cooperate
/// with this session — it *replaces* it, and the eviction arrives here looking
/// exactly like a phone call. That is why every `RecordConfig` in this feature
/// passes `audioInterruption: AudioInterruptionMode.none`; see
/// `RecordVoiceCapture.captureConfig`.
class AudioSessionManager {
  /// Creates the manager.
  AudioSessionManager();

  /// The session used to capture.
  ///
  /// `playAndRecord` because the same session plays the assistant's reply back
  /// moments later, and because `playback` alone cannot capture on iOS at all.
  /// `gainTransientExclusive` because a session is transient and must not be
  /// mixed into — the OS should hand the previous owner its audio back when we
  /// are done, and should not offer to duck us instead of pausing.
  ///
  /// `final` rather than `const` only because `AVAudioSessionCategoryOptions`
  /// composes with a non-const `|`.
  static final AudioSessionConfiguration recordingConfiguration =
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth,
        // `defaultMode` rather than `voiceChat`: voice chat engages the
        // communication path and its aggressive processing, which is right for
        // a duplex call and wrong for capture the user expects to sound like
        // their own voice.
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientExclusive,
        // A duck request must not stop capture, so it is delivered as a duck
        // rather than rewritten into a pause. See [AudioSessionEvent.ducked].
        androidWillPauseWhenDucked: false,
      );

  /// The session used to play the assistant's reply back.
  ///
  /// `speech()` asks the OS for the spoken-word profile, which is what a
  /// spoken reply is. Ducking is rewritten to a pause here because a
  /// half-audible sentence is worse than a paused one.
  static const AudioSessionConfiguration playbackConfiguration =
      AudioSessionConfiguration.speech();

  AudioSession? _session;
  AudioSessionMode? _configuredMode;
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  StreamSubscription<void>? _noisy;

  final StreamController<AudioSessionEvent> _events =
      StreamController<AudioSessionEvent>.broadcast();

  bool _disposed = false;

  /// Interruptions and route losses, for whoever currently holds the session.
  Stream<AudioSessionEvent> get events => _events.stream;

  /// Which mode the session is currently configured for, or `null` before the
  /// first [activate]. Exposed for tests and diagnostics.
  AudioSessionMode? get configuredMode => _configuredMode;

  /// Classifies a platform interruption.
  ///
  /// Pure and static so the decision that used to be buried behind a plugin
  /// can be asserted directly — the same shape as
  /// `PermissionsAiPermissionGateway.mapPermissionResult`.
  ///
  /// The `duck` split is the point: `audio_session` reports a
  /// `AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK` as a *beginning* interruption, and
  /// collapsing that into [AudioSessionEvent.interrupted] would end a
  /// recording every time a notification arrived.
  static AudioSessionEvent mapInterruption(AudioInterruptionEvent event) {
    if (!event.begin) return AudioSessionEvent.resumed;
    return event.type == AudioInterruptionType.duck
        ? AudioSessionEvent.ducked
        : AudioSessionEvent.interrupted;
  }

  /// Configures the session for [mode] and subscribes to its signals.
  ///
  /// Reconfigures when the mode changes, which is the whole reason the mode is
  /// a parameter: the previous version configured once, on first use, and
  /// whichever of recording or playback happened first silently decided the
  /// category for the rest of the visit.
  Future<void> _ensureConfigured(AudioSessionMode mode) async {
    if (_disposed || _configuredMode == mode) return;

    final session = _session ?? await AudioSession.instance;
    if (_disposed) return;

    await session.configure(
      mode == AudioSessionMode.recording
          ? recordingConfiguration
          : playbackConfiguration,
    );
    if (_disposed) return;

    _configuredMode = mode;
    if (_session != null) return;

    _session = session;
    _interruptions = session.interruptionEventStream.listen(
      (event) => _emit(mapInterruption(event)),
    );
    _noisy = session.becomingNoisyEventStream.listen(
      (_) => _emit(AudioSessionEvent.becameNoisy),
    );
  }

  /// Configures for [mode], then takes audio focus. Safe to call more than
  /// once.
  ///
  /// Returns whether focus was actually granted — it is refused during a call,
  /// and a caller that opened the microphone anyway would be recording into a
  /// session the OS has already given to someone else.
  Future<bool> activate(AudioSessionMode mode) async {
    await _ensureConfigured(mode);
    if (_disposed) return false;
    return await _session?.setActive(true) ?? false;
  }

  /// Gives audio focus back, so music the user had playing can resume.
  Future<void> deactivate() async {
    if (_disposed) return;
    await _session?.setActive(false);
  }

  /// Releases the subscriptions and the focus. Safe to call twice.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _interruptions?.cancel();
    await _noisy?.cancel();
    _interruptions = null;
    _noisy = null;

    // Best effort: a session that was never configured has nothing to release,
    // and a platform that refuses must not turn teardown into a crash.
    try {
      await _session?.setActive(false);
    } on Object {
      // Ignored on purpose — see above.
    }
    _session = null;
    _configuredMode = null;

    if (!_events.isClosed) await _events.close();
  }

  void _emit(AudioSessionEvent event) {
    if (_disposed || _events.isClosed) return;
    _events.add(event);
  }
}
