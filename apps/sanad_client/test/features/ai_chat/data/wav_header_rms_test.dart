import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/wav_header.dart';

/// Measuring loudness of a PCM frame.
///
/// The alignment group is the regression. `record` hands out frames that are
/// **views** into a larger buffer, and on a real device that view's byte offset
/// is routinely odd. `asInt16List` refuses a byte offset that is not a multiple
/// of two, so every frame threw `RangeError` — silently killing the live-voice
/// level meter and the silence detector for the entire session while the UI
/// went on claiming to listen.
void main() {
  /// Builds a frame at [offset] bytes into a larger buffer, so the returned
  /// list is a view rather than its own allocation — exactly what the plugin
  /// produces.
  Uint8List viewAt(int offset, List<int> samples) {
    final backing = Uint8List(offset + samples.length * 2);
    final view = ByteData.sublistView(backing, offset);
    for (var i = 0; i < samples.length; i++) {
      view.setInt16(i * 2, samples[i], Endian.little);
    }
    return Uint8List.sublistView(backing, offset);
  }

  group('it reads a frame at any alignment', () {
    test('an odd offset does not throw', () {
      // Offset 5 is the value observed on device.
      expect(() => WavHeader.rms(viewAt(5, [16384, -16384])), returnsNormally);
    });

    test('every offset up to a word boundary agrees', () {
      const samples = [16384, -16384, 16384, -16384];
      final aligned = WavHeader.rms(viewAt(0, samples));

      for (var offset = 1; offset <= 5; offset++) {
        expect(
          WavHeader.rms(viewAt(offset, samples)),
          closeTo(aligned, 1e-9),
          reason: 'offset $offset must measure the same audio',
        );
      }
    });
  });

  group('it measures what it should', () {
    test('digital silence is zero', () {
      expect(WavHeader.rms(viewAt(0, [0, 0, 0, 0])), 0);
    });

    test('full scale is one', () {
      expect(WavHeader.rms(viewAt(0, [32767, -32767])), closeTo(1, 0.001));
    });

    test('half scale is half', () {
      // A square wave at half amplitude has an RMS of exactly half.
      expect(WavHeader.rms(viewAt(0, [16384, -16384])), closeTo(0.5, 0.001));
    });

    test('louder audio always reads higher', () {
      final quiet = WavHeader.rms(viewAt(0, [1000, -1000]));
      final loud = WavHeader.rms(viewAt(0, [20000, -20000]));

      expect(loud, greaterThan(quiet));
    });

    test('it is little-endian, as PCM16 is', () {
      // 0x0100 read the wrong way round would be 1 rather than 256.
      final frame = Uint8List.fromList([0x00, 0x01]);
      expect(WavHeader.rms(frame), closeTo(256 / 32768, 1e-9));
    });
  });

  group('degenerate frames do not explode', () {
    test('an empty frame is silent', () {
      expect(WavHeader.rms(Uint8List(0)), 0);
    });

    test('a single stray byte is silent rather than a crash', () {
      expect(WavHeader.rms(Uint8List(1)), 0);
    });

    test('an odd byte count ignores the trailing half-sample', () {
      final odd = Uint8List.fromList([0x00, 0x40, 0x7f]);
      expect(() => WavHeader.rms(odd), returnsNormally);
      expect(WavHeader.rms(odd), closeTo(0.5, 0.001));
    });
  });
}
