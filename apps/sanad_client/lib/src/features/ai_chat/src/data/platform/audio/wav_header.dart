import 'dart:math' as math;
import 'dart:typed_data';

/// Builds the 44-byte RIFF/WAVE header that turns raw PCM into a playable file.
///
/// Hand-written rather than pulled in as a dependency: it is a fixed 44-byte
/// structure, and a package for it would be more code to audit than the code
/// it replaces.
///
/// The live-voice mock captures raw PCM frames and writes them straight to
/// disk as they arrive — never accumulating them in memory — then prepends
/// this header so `just_audio` can play the result back. That round trip is
/// what makes the echoed "assistant" reply proof that capture actually worked,
/// rather than a canned clip that would prove nothing.
abstract final class WavHeader {
  /// The fixed size of a canonical RIFF/WAVE header.
  static const int byteLength = 44;

  /// Builds a header describing [dataBytes] of PCM.
  static Uint8List build({
    required int dataBytes,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final header = ByteData(byteLength)
      // "RIFF"
      ..setUint8(0, 0x52)
      ..setUint8(1, 0x49)
      ..setUint8(2, 0x46)
      ..setUint8(3, 0x46)
      // Everything after this field: 36 + payload.
      ..setUint32(4, 36 + dataBytes, Endian.little)
      // "WAVE"
      ..setUint8(8, 0x57)
      ..setUint8(9, 0x41)
      ..setUint8(10, 0x56)
      ..setUint8(11, 0x45)
      // "fmt "
      ..setUint8(12, 0x66)
      ..setUint8(13, 0x6D)
      ..setUint8(14, 0x74)
      ..setUint8(15, 0x20)
      // Sub-chunk size: 16 for PCM.
      ..setUint32(16, 16, Endian.little)
      // Format: 1 is uncompressed PCM.
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, byteRate, Endian.little)
      ..setUint16(32, blockAlign, Endian.little)
      ..setUint16(34, bitsPerSample, Endian.little)
      // "data"
      ..setUint8(36, 0x64)
      ..setUint8(37, 0x61)
      ..setUint8(38, 0x74)
      ..setUint8(39, 0x61)
      ..setUint32(40, dataBytes, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Root-mean-square loudness of a 16-bit little-endian PCM [frame],
  /// normalised to 0..1.
  ///
  /// RMS rather than peak: a peak meter jumps on a single click and reads
  /// almost the same for a whisper and a shout, whereas RMS tracks perceived
  /// loudness — which is what both the level meter and the silence detector
  /// actually need.
  /// Read through a [ByteData] view rather than `asInt16List`, which requires
  /// the byte offset to be a multiple of two. `record` hands out frames that
  /// are *views* into a larger buffer, and on a real device that offset is
  /// routinely odd — which threw `RangeError: Offset (5) must be a multiple of
  /// BYTES_PER_ELEMENT (2)` on every single frame, silently killing the level
  /// meter and the silence detector for the whole session. `ByteData` has no
  /// alignment constraint and copies nothing.
  static double rms(Uint8List frame) {
    if (frame.length < 2) return 0;

    final bytes = ByteData.sublistView(frame);
    final sampleCount = bytes.lengthInBytes ~/ 2;
    if (sampleCount == 0) return 0;

    var sumOfSquares = 0.0;
    for (var i = 0; i < sampleCount; i++) {
      final normalised = bytes.getInt16(i * 2, Endian.little) / 32768.0;
      sumOfSquares += normalised * normalised;
    }

    return math.sqrt(sumOfSquares / sampleCount).clamp(0.0, 1.0);
  }
}
