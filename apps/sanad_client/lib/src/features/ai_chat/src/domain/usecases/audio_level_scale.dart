import 'dart:math' as math;

/// Turns a raw loudness measurement into the 0..1 a meter can draw.
///
/// Pure domain arithmetic, deliberately: the platform hands us decibels or
/// linear RMS depending on which microphone path is open, and neither is a
/// height. Doing this conversion in a `CustomPainter` would put signal maths
/// in the widget layer and make it untestable; doing it in each adapter would
/// give the voice meter and the recording meter two different ideas of what
/// "loud" means.
abstract final class AudioLevelScale {
  /// The quietest level the meter shows, in dBFS.
  ///
  /// Everything below this reads as silence. The platform reports a **peak**
  /// sample as `20·log10(peak / 32767)`, whose useful range runs from about
  /// -160 dBFS (digital silence) up to 0 (clipping). Room tone on a phone
  /// typically peaks around -60 to -50 dBFS and ordinary speech at arm's
  /// length around -30 to -6, so anchoring at -60 keeps quiet speech visible.
  ///
  /// The previous -45 was too high: it mapped anything quieter than a raised
  /// voice to exactly zero, so a normal conversational take drew a flat line.
  static const double floorDb = -60;

  /// The loudest, in dBFS. Zero is digital full scale.
  static const double ceilingDb = 0;

  /// Below this linear amplitude the signal is treated as digital silence,
  /// which also keeps `log10(0)` — negative infinity — out of the arithmetic.
  static const double silenceFloor = 1e-6;

  /// How much of the gap to the new value a *falling* level closes per tick.
  ///
  /// Attack is instant and release is gradual, which is what every level meter
  /// does: a peak measurement is spiky, and following it downwards frame for
  /// frame makes the meter flicker rather than read as loudness. At the
  /// recorder's 120 ms tick this decays to the floor over roughly half a
  /// second, so falling silent visibly settles instead of snapping to zero.
  static const double releaseFactor = 0.35;

  /// Maps a dBFS reading onto 0..1.
  ///
  /// Linear in decibels rather than in amplitude, because decibels are already
  /// the perceptual scale — a linear-amplitude meter spends almost all of its
  /// travel on the loudest few percent of the range and looks dead the rest of
  /// the time.
  static double fromDbfs(double db) {
    // Not-a-number and negative infinity both mean "nothing measured".
    // Positive infinity cannot happen from a real device but must not escape
    // as a NaN height if it ever does.
    if (db.isNaN) return 0;
    if (db.isInfinite) return db.isNegative ? 0 : 1;
    if (db <= floorDb) return 0;
    if (db >= ceilingDb) return 1;
    return (db - floorDb) / (ceilingDb - floorDb);
  }

  /// Maps a linear amplitude — an RMS in 0..1, as the PCM path produces —
  /// onto the same scale.
  ///
  /// Converting through decibels rather than using the RMS directly is the
  /// point. Speech RMS sits around 0.02 to 0.10, so a meter driven by the raw
  /// value would never leave the bottom tenth of its travel however loudly
  /// someone spoke.
  static double fromLinear(double amplitude) {
    if (amplitude.isNaN || amplitude <= silenceFloor) return 0;
    final clamped = amplitude > 1 ? 1.0 : amplitude;
    return fromDbfs(20 * math.log(clamped) / math.ln10);
  }

  /// Applies the attack/release curve between two consecutive readings.
  static double release(double previous, double next) {
    if (!previous.isFinite || !next.isFinite) return 0;
    if (next >= previous) return next;
    return previous + (next - previous) * releaseFactor;
  }
}

/// A running peak envelope of a take, for the waveform a finished recording
/// keeps.
///
/// This exists because the saved waveform used to be *fabricated*: it took the
/// single most recent level and smeared it across forty bars with a fixed
/// pattern, so every recording drew the same shape and a quiet one drew a flat
/// line. Nothing about it described the audio.
///
/// It is bounded on purpose. A five-minute take ticks about 2500 times, and
/// keeping every reading for the life of the message is exactly the retention
/// the feature avoids elsewhere. Instead the envelope folds itself in half by
/// pairwise maximum whenever it outgrows [capacity], so it never holds more
/// than that many values and still describes the whole take — the standard
/// streaming downsample, and the reason peaks survive rather than averaging
/// away into a flat middle.
final class AudioLevelEnvelope {
  /// Creates an empty envelope.
  AudioLevelEnvelope({this.capacity = 128}) : assert(capacity > 1, 'need room');

  /// The most readings held before folding.
  final int capacity;

  final List<double> _peaks = <double>[];

  /// How many raw readings each stored peak currently covers.
  int _span = 1;

  /// How many readings have gone into the newest peak so far.
  int _filled = 0;

  /// Whether anything has been recorded yet.
  bool get isEmpty => _peaks.isEmpty;

  /// How many peaks are currently held. Exposed for tests.
  int get length => _peaks.length;

  /// Folds one reading in.
  void add(double level) {
    final value = level.isFinite ? level.clamp(0.0, 1.0) : 0.0;

    if (_filled == 0) {
      _peaks.add(value);
    } else if (value > _peaks.last) {
      _peaks[_peaks.length - 1] = value;
    }

    _filled++;
    if (_filled >= _span) _filled = 0;
    if (_peaks.length > capacity) _fold();
  }

  /// Halves the resolution, keeping the louder of each pair.
  void _fold() {
    final kept = (_peaks.length + 1) ~/ 2;
    for (var i = 0; i < _peaks.length ~/ 2; i++) {
      _peaks[i] = math.max(_peaks[i * 2], _peaks[i * 2 + 1]);
    }
    // An odd tail has no partner; it carries over as-is rather than being
    // dropped, so the end of a take is never silently truncated.
    if (_peaks.length.isOdd) _peaks[kept - 1] = _peaks[_peaks.length - 1];
    _peaks.removeRange(kept, _peaks.length);

    _span *= 2;
    _filled = 0;
  }

  /// Renders the envelope as exactly [count] bars.
  ///
  /// Always returns [count] values so the waveform widget never has to reason
  /// about a short or empty list; a take with no readings at all comes back
  /// silent rather than absent.
  List<double> resample(int count) {
    if (count <= 0) return const <double>[];
    if (_peaks.isEmpty) return List<double>.filled(count, 0);

    return List<double>.generate(count, (i) {
      final start = i * _peaks.length ~/ count;
      final end = math.max(start + 1, (i + 1) * _peaks.length ~/ count);
      var peak = 0.0;
      for (var j = start; j < end && j < _peaks.length; j++) {
        if (_peaks[j] > peak) peak = _peaks[j];
      }
      return peak;
    });
  }

  /// Forgets everything, for the next take.
  void reset() {
    _peaks.clear();
    _span = 1;
    _filled = 0;
  }
}
