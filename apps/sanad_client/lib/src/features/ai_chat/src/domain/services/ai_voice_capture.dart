import 'dart:typed_data';

/// The shape of the audio the microphone is opened with.
///
/// Fixed rather than configurable: 16 kHz mono 16-bit PCM is what every
/// realtime speech transport expects, and pinning it here means the WAV the
/// mock writes and the frames a future transport would send are the same
/// bytes.
abstract final class AiVoiceAudioFormat {
  /// Samples per second.
  static const int sampleRate = 16000;

  /// Mono.
  static const int channels = 1;

  /// Signed 16-bit samples.
  static const int bitsPerSample = 16;
}

/// Opens the microphone as a raw PCM stream.
///
/// Deliberately *streaming* rather than file-based: a realtime session needs
/// frames as they are captured, not a file when the user stops. That is also
/// what makes this the seam a real transport would plug into — the frames it
/// yields are exactly what would go on the wire.
///
/// This is live-voice infrastructure and nothing else. The chat composer has
/// no capture path at all: its microphone capability is speech recognition,
/// which returns words rather than audio.
abstract interface class AiVoiceCapture {
  /// Whether the device has a microphone this capture can use.
  Future<bool> get isAvailable;

  /// Opens the microphone and begins yielding PCM frames.
  Future<Stream<Uint8List>> start();

  /// Closes the microphone. Safe when it was never opened.
  Future<void> stop();

  /// Releases everything. Safe while capturing, and safe to call twice.
  Future<void> dispose();
}
