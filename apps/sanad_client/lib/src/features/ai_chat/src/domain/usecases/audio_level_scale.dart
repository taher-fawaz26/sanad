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
