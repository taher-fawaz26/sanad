import 'dart:async';

import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Dictation with the device's own speech recogniser.
///
/// The only file in the feature that names `speech_to_text`.
///
/// ## It does not touch the audio session — on purpose
///
/// Every other microphone path here activates `AudioSessionManager` first. This
/// one must not, and that is a decision rather than an oversight. On Android
/// the plugin binds the system `SpeechRecognizer`, which runs in the recogniser
/// app's process and manages its own capture; the plugin itself requests no
/// audio focus at all. Taking `GAIN_TRANSIENT_EXCLUSIVE` here would therefore
/// not protect anything — it would only give us a focus grant to fight the
/// recogniser with, and hand our own listener a loss to misread. Mutual
/// exclusion against recording and playback is enforced one level up, in
/// `AiComposerBloc`, where it can be a decision instead of a race.
///
/// ## The plugin is a singleton
///
/// `SpeechToText()` is a factory returning one shared instance, and it has no
/// `dispose()`. So this adapter owns its *listeners*, not the plugin: teardown
/// cancels any live session and detaches, leaving the instance reusable by the
/// next visit to the chat.
class SpeechToTextRecognizer implements AiSpeechRecognizer {
  /// Creates the recogniser.
  ///
  /// [speech] is injectable so a test can drive the adapter's mapping without
  /// a platform channel.
  SpeechToTextRecognizer({stt.SpeechToText? speech})
    : _speech = speech ?? stt.SpeechToText();

  /// How long a single dictation may run before the platform ends it.
  ///
  /// Generous, because the alternative is cutting someone off mid-sentence.
  /// The user's own stop is the normal way this ends.
  static const Duration maxListenDuration = Duration(minutes: 2);

  /// How much silence ends a phrase.
  ///
  /// Longer than the plugin's default: it is tuned for short commands, and a
  /// person composing a message pauses to think.
  static const Duration pauseDuration = Duration(seconds: 4);

  final stt.SpeechToText _speech;

  final StreamController<AiSpeechTranscript> _transcripts =
      StreamController<AiSpeechTranscript>.broadcast();
  final StreamController<AiSpeechFailure> _failures =
      StreamController<AiSpeechFailure>.broadcast();
  final StreamController<bool> _listening = StreamController<bool>.broadcast();

  bool _initialised = false;
  bool _disposed = false;
  bool _wasListening = false;

  @override
  Stream<AiSpeechTranscript> get transcripts => _transcripts.stream;

  @override
  Stream<AiSpeechFailure> get failures => _failures.stream;

  @override
  Stream<bool> get listening => _listening.stream;

  /// Maps a platform error onto a product reason.
  ///
  /// Pure and static so the whole table is assertable without a device — the
  /// same shape as `PermissionsAiPermissionGateway.mapPermissionResult` and
  /// `RecordAudioRecorder.abortFor`.
  ///
  /// The identifiers are Android's `SpeechRecognizer` error names, which the
  /// plugin also uses on iOS. [permanent] is the plugin's own flag for "this
  /// will not succeed if you try again".
  static AiSpeechFailure mapError(
    String errorMsg, {
    required bool permanent,
  }) => switch (errorMsg) {
    'error_permission' || 'error_permission_denied' =>
      permanent
          ? AiSpeechFailure.permissionPermanentlyDenied
          : AiSpeechFailure.permissionDenied,
    'error_no_match' => AiSpeechFailure.noMatch,
    'error_speech_timeout' ||
    'error_no_speech_timeout' => AiSpeechFailure.timeout,
    'error_network' || 'error_network_timeout' => AiSpeechFailure.network,
    'error_language_not_supported' ||
    'error_language_unavailable' ||
    'error_busy' ||
    'error_client' => AiSpeechFailure.unavailable,
    _ => AiSpeechFailure.platform,
  };

  @override
  Future<bool> initialize() async {
    if (_disposed) return false;
    if (_initialised) return _speech.isAvailable;

    try {
      return _initialised = await _speech.initialize(
        onStatus: _onStatus,
        onError: (error) =>
            _fail(mapError(error.errorMsg, permanent: error.permanent)),
      );
    } on Object {
      // A missing recogniser throws on some devices rather than returning
      // false. Either way it is the same product outcome.
      return false;
    }
  }

  @override
  Future<List<String>> availableLocales() async {
    if (_disposed || !await initialize()) return const [];
    try {
      final locales = await _speech.locales();
      return [for (final locale in locales) locale.localeId];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> start({String? localeId}) async {
    if (_disposed) return;

    if (!await initialize()) {
      _fail(AiSpeechFailure.unavailable);
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) => _emit(
          AiSpeechTranscript(
            text: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        ),
        listenOptions: stt.SpeechListenOptions(
          // Named even though it is the plugin default: live partial text is
          // the entire point of this screen, and a default that flipped
          // underneath us would turn dictation into a blank wait.
          // ignore: avoid_redundant_argument_values
          partialResults: true,
          // Stop on the first error rather than limping on: a half-dead
          // recogniser that never reports again would leave the composer
          // claiming to listen forever.
          cancelOnError: true,
          // Dictation rather than the default `confirmation`, which is built
          // for one-word commands and ends almost immediately.
          listenMode: stt.ListenMode.dictation,
          localeId: localeId,
          pauseFor: pauseDuration,
          listenFor: maxListenDuration,
        ),
      );
    } on Object {
      _fail(AiSpeechFailure.platform);
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _speech.stop();
    } on Object {
      // Stopping something already stopped is not an error.
    }
  }

  @override
  Future<void> cancel() async {
    if (_disposed) return;
    try {
      await _speech.cancel();
    } on Object {
      // As above.
    }
    _setListening(false);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // The plugin instance is shared and outlives us, so hand the microphone
    // back rather than leaving a session running for the next screen to find.
    try {
      await _speech.cancel();
    } on Object {
      // Nothing was running.
    }

    if (!_transcripts.isClosed) await _transcripts.close();
    if (!_failures.isClosed) await _failures.close();
    if (!_listening.isClosed) await _listening.close();
  }

  /// Translates the plugin's status strings into the listening signal.
  ///
  /// The platform is the authority here: a recogniser tuned for short phrases
  /// ends the session itself after a pause, and the composer has to follow that
  /// rather than keep claiming to listen.
  void _onStatus(String status) => _setListening(
    status == stt.SpeechToText.listeningStatus,
  );

  void _setListening(bool value) {
    if (_disposed || _listening.isClosed || value == _wasListening) return;
    _wasListening = value;
    _listening.add(value);
  }

  void _emit(AiSpeechTranscript transcript) {
    if (_disposed || _transcripts.isClosed) return;
    _transcripts.add(transcript);
  }

  void _fail(AiSpeechFailure failure) {
    if (_disposed || _failures.isClosed) return;
    _failures.add(failure);
  }
}
