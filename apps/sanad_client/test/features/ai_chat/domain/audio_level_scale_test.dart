import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/audio_level_scale.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/level_history.dart';

/// The flat-meter regression.
///
/// The live meter drew a constant dotted line. Three separate causes, all
/// covered here:
///
/// 1. the dBFS floor was -45, which mapped ordinary conversational speech to
///    exactly zero;
/// 2. the voice path fed the meter a raw linear RMS, whose speech range is
///    roughly 0.02..0.10 — the bottom tenth of the meter's travel;
/// 3. the saved waveform was fabricated from a single scalar and kept no
///    history of the take at all.
void main() {
  group('AudioLevelScale.fromDbfs', () {
    test('digital silence reads zero', () {
      expect(AudioLevelScale.fromDbfs(-160), 0);
      expect(AudioLevelScale.fromDbfs(double.negativeInfinity), 0);
    });

    test('full scale reads one', () {
      expect(AudioLevelScale.fromDbfs(0), 1);
    });

    test('the emulator floor this bug was found on still reads silent', () {
      // The measured value on the test emulator, whose virtual microphone
      // emits a bit-exact constant. It is genuinely silence and must read as
      // such — the fix must not manufacture movement out of a dead input.
      expect(AudioLevelScale.fromDbfs(-71.22), 0);
    });

    test('conversational speech is clearly visible', () {
      // The regression proper. Under the old -45 floor every one of these
      // mapped to 0 or nearly 0, so a normal take drew a flat line.
      expect(AudioLevelScale.fromDbfs(-30), greaterThan(0.4));
      expect(AudioLevelScale.fromDbfs(-20), greaterThan(0.6));
      expect(AudioLevelScale.fromDbfs(-6), greaterThan(0.85));
    });

    test('quiet room tone stays low but is not necessarily zero', () {
      final roomTone = AudioLevelScale.fromDbfs(-55);
      expect(roomTone, lessThan(0.15));
      expect(roomTone, greaterThanOrEqualTo(0));
    });

    test('louder input always reads higher', () {
      var previous = -1.0;
      for (var db = -70.0; db <= 0; db += 5) {
        final level = AudioLevelScale.fromDbfs(db);
        expect(level, greaterThanOrEqualTo(previous));
        previous = level;
      }
    });

    test('nonsense input does not explode', () {
      for (final db in [double.nan, double.infinity, 1e9, -1e9]) {
        final level = AudioLevelScale.fromDbfs(db);
        expect(level.isFinite, isTrue, reason: '$db produced $level');
        expect(level, inInclusiveRange(0, 1));
      }
    });
  });

  group('AudioLevelScale.fromLinear', () {
    test('zero and negative amplitudes read silent', () {
      expect(AudioLevelScale.fromLinear(0), 0);
      expect(AudioLevelScale.fromLinear(-1), 0);
    });

    test('speech-range RMS is visible rather than a sliver', () {
      // The voice-path regression. Fed raw, an RMS of 0.05 drew a bar 5% tall.
      expect(AudioLevelScale.fromLinear(0.05), greaterThan(0.4));
      expect(AudioLevelScale.fromLinear(0.1), greaterThan(0.5));
    });

    test('speech is well separated from room tone', () {
      final tone = AudioLevelScale.fromLinear(0.005);
      final speech = AudioLevelScale.fromLinear(0.08);
      expect(speech - tone, greaterThan(0.25));
    });

    test('over-unity and nonsense clamp safely', () {
      expect(AudioLevelScale.fromLinear(5), 1);
      expect(AudioLevelScale.fromLinear(double.nan), 0);
    });
  });

  group('AudioLevelScale.release', () {
    test('a rise is immediate', () {
      expect(AudioLevelScale.release(0.1, 0.9), 0.9);
    });

    test('a fall decays rather than snapping', () {
      final decayed = AudioLevelScale.release(1, 0);
      expect(decayed, greaterThan(0));
      expect(decayed, lessThan(1));
    });

    test('sustained silence decays to the floor', () {
      var level = 1.0;
      for (var i = 0; i < 40; i++) {
        level = AudioLevelScale.release(level, 0);
      }
      expect(level, lessThan(0.01));
    });

    test('nonsense input does not explode', () {
      expect(AudioLevelScale.release(double.nan, 0.5), 0);
      expect(AudioLevelScale.release(0.5, double.nan), 0);
    });
  });

  group('AudioLevelEnvelope', () {
    test('an empty take still yields the requested number of bars', () {
      final envelope = AudioLevelEnvelope();
      final bars = envelope.resample(40);

      expect(bars, hasLength(40));
      expect(bars.every((b) => b == 0), isTrue);
    });

    test('it describes the take rather than repeating one value', () {
      // The saved-waveform regression: the old code smeared the *last* level
      // across every bar, so a take that was loud then quiet drew the same
      // shape as one that was quiet throughout.
      final envelope = AudioLevelEnvelope();
      for (var i = 0; i < 50; i++) {
        envelope.add(1);
      }
      for (var i = 0; i < 50; i++) {
        envelope.add(0);
      }

      final bars = envelope.resample(10);
      expect(bars.first, 1, reason: 'the loud opening must survive');
      expect(bars.last, 0, reason: 'the quiet ending must survive');
    });

    test('it stays bounded across a long take', () {
      final envelope = AudioLevelEnvelope(capacity: 32);
      // A five-minute take at the recorder's 120 ms tick.
      for (var i = 0; i < 2500; i++) {
        envelope.add(0.5);
      }

      expect(envelope.length, lessThanOrEqualTo(32));
      expect(envelope.resample(40), hasLength(40));
    });

    test('a peak survives folding', () {
      // Folding keeps the louder of each pair, so a single shout in a long
      // quiet take is still visible rather than averaged away.
      final envelope = AudioLevelEnvelope(capacity: 8);
      for (var i = 0; i < 200; i++) {
        envelope.add(i == 100 ? 1.0 : 0.0);
      }

      expect(envelope.resample(40).any((b) => b > 0.9), isTrue);
    });

    test('nonsense readings do not explode', () {
      final envelope = AudioLevelEnvelope()
        ..add(double.nan)
        ..add(double.infinity)
        ..add(-5)
        ..add(9);

      final bars = envelope.resample(4);
      expect(bars.every((b) => b.isFinite && b >= 0 && b <= 1), isTrue);
    });

    test('reset forgets the previous take', () {
      final envelope = AudioLevelEnvelope()..add(1);
      expect(envelope.isEmpty, isFalse);

      envelope.reset();
      expect(envelope.isEmpty, isTrue);
      expect(envelope.resample(4), everyElement(0));
    });
  });

  group('LevelHistory', () {
    test('it always offers a full window', () {
      final history = LevelHistory(length: 8);
      expect(history.values, hasLength(8));

      history.add(1);
      expect(history.values, hasLength(8));
      expect(history.values.last, 1, reason: 'newest goes at the end');
      expect(history.values.first, 0, reason: 'padded with silence');
    });

    test('it scrolls, dropping the oldest', () {
      final history = LevelHistory(length: 3);
      for (final value in [0.1, 0.2, 0.3, 0.4]) {
        history.add(value);
      }

      expect(history.values, [0.2, 0.3, 0.4]);
    });

    test('each change is a new list, so a painter can compare identity', () {
      final history = LevelHistory(length: 4);
      final before = history.values;
      history.add(0.5);

      expect(identical(before, history.values), isFalse);
    });

    test('nonsense readings clamp', () {
      final history = LevelHistory(length: 2)
        ..add(double.nan)
        ..add(42);

      expect(history.values, [0, 1]);
    });

    test('clear returns to silence', () {
      final history = LevelHistory(length: 3)
        ..add(1)
        ..clear();

      expect(history.values, [0, 0, 0]);
    });
  });
}
