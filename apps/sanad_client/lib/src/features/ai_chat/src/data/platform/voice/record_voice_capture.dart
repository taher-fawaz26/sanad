import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_capture.dart';

/// Opens the real microphone as a PCM stream with `record`.
///
/// Uses `startStream` rather than `start(path:)` on purpose. A realtime
/// session needs frames as they are spoken — to drive a level meter, to detect
/// that the user stopped talking, and eventually to put on a wire — and a file
/// that only exists once the user stops cannot do any of that.
///
/// This is the seam a real transport replaces: the frames yielded here are
/// 16 kHz mono 16-bit PCM, which is what a realtime speech API expects.
class RecordVoiceCapture implements AiVoiceCapture {
  /// Creates the capture.
  RecordVoiceCapture();

  /// How the live session captures.
  ///
  /// `audioInterruption: none` because `AudioSessionManager` is this
  /// feature's single audio-focus client, and letting `record` request focus
  /// of its own evicts the session that was activated moments earlier — which
  /// arrives back as an interruption and ends the call the instant it starts.
  static const RecordConfig captureConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: AiVoiceAudioFormat.sampleRate,
    numChannels: AiVoiceAudioFormat.channels,
    // Both on because the assistant's reply plays out of the same speaker
    // the microphone is listening through. Without them the session hears
    // itself and the level meter tracks the reply rather than the user.
    echoCancel: true,
    noiseSuppress: true,
    audioInterruption: AudioInterruptionMode.none,
  );

  final AudioRecorder _recorder = AudioRecorder();
  bool _capturing = false;
  bool _disposed = false;

  @override
  Future<bool> get isAvailable async {
    if (_disposed) return false;
    try {
      return _recorder.isEncoderSupported(AudioEncoder.pcm16bits);
    } on Object {
      return false;
    }
  }

  @override
  Future<Stream<Uint8List>> start() async {
    if (_disposed) return const Stream<Uint8List>.empty();

    final stream = await _recorder.startStream(captureConfig);
    _capturing = true;
    return stream;
  }

  @override
  Future<void> stop() async {
    if (!_capturing) return;
    _capturing = false;
    try {
      await _recorder.stop();
    } on Object {
      // Stopping something already stopped is not an error.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await stop();
    await _recorder.dispose();
  }
}
