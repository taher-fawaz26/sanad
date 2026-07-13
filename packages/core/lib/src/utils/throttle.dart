/// Fires immediately, then ignores further calls for [duration].
class Throttle {
  Throttle({this.duration = const Duration(milliseconds: 500)});

  final Duration duration;
  bool _isReady = true;

  void run(void Function() callback) {
    if (!_isReady) return;
    _isReady = false;
    callback();
    Future<void>.delayed(duration, () => _isReady = true);
  }

  void reset() => _isReady = true;
}
