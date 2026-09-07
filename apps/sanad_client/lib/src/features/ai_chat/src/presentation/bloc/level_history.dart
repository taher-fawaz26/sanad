/// A short rolling window of recent audio levels.
///
/// Shared by the recording meter and the voice meter, which need the same
/// thing for the same reason: a level meter driven by a single number can only
/// grow and shrink in place. Showing that someone started talking, trailed off
/// and stopped needs a *series*, and this is the smallest thing that keeps one.
///
/// It is deliberately not a `ValueNotifier` of its own. The controllers that
/// own it already notify once per tick, and a second notifier for the same
/// tick would double the rebuilds this whole architecture exists to avoid.
final class LevelHistory {
  /// Creates a window of [length] silent bars.
  LevelHistory({this.length = defaultLength})
    : assert(length > 0, 'need bars') {
    _values = _silence;
  }

  /// Enough bars to read as a waveform at the width the composer gives it,
  /// and few enough that rebuilding the list once per tick stays trivial.
  static const int defaultLength = 32;

  /// How many readings the window holds.
  final int length;

  final List<double> _window = <double>[];

  late List<double> _values;

  List<double> get _silence => List<double>.unmodifiable(
    List<double>.filled(length, 0),
  );

  /// The window, oldest first, left-padded with silence until it fills.
  ///
  /// Always exactly [length] values, so a painter never has to reason about a
  /// half-full window. A new list whenever it changes, so a `CustomPainter`
  /// comparing by identity repaints exactly when there is something new.
  List<double> get values => _values;

  /// Pushes one reading, dropping the oldest once the window is full.
  void add(double level) {
    _window.add(level.isFinite ? level.clamp(0.0, 1.0) : 0.0);
    if (_window.length > length) _window.removeAt(0);

    _values = List<double>.unmodifiable([
      ...List<double>.filled(length - _window.length, 0),
      ..._window,
    ]);
  }

  /// Empties the window back to silence.
  void clear() {
    _window.clear();
    _values = _silence;
  }
}
