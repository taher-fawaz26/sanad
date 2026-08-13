import 'package:flutter/widgets.dart';

/// Drives show/hide state for a persistent bottom navigation bar from a
/// [ScrollController] (typically the shell's shared controller exposed via
/// `MainNavScrollController`).
///
/// Replaces "any scroll-direction change hides the bar" logic, which
/// mishandles three cases: short/non-scrollable content (a 1-3 item list
/// reports a tiny `maxScrollExtent`, so it should never hide), pull-to-refresh
/// (overscroll at the top isn't a real scroll intent), and tiny/accidental
/// drags (should not toggle visibility).
///
/// Rules:
/// * Content whose `maxScrollExtent` is at or below [minScrollExtentThreshold]
///   is treated as non-scrollable — the bar always stays visible.
/// * Visibility only changes once the user has scrolled more than
///   [scrollThreshold] logical pixels in one direction since the last
///   direction change — filters out tiny gestures.
/// * Returning to (or starting at) the top always shows the bar.
/// * Overscroll (bounce, pull-to-refresh) never changes visibility on its
///   own — it isn't a real scroll.
class NavVisibilityController extends ChangeNotifier {
  /// Creates a controller. [attach] it to the scroll controller that should
  /// drive it.
  NavVisibilityController({
    this.scrollThreshold = 24,
    this.minScrollExtentThreshold = 40,
  });

  /// Minimum accumulated scroll delta (logical pixels) in one direction
  /// before visibility changes.
  final double scrollThreshold;

  /// At or below this `maxScrollExtent`, content is non-scrollable and the
  /// bar never hides.
  final double minScrollExtentThreshold;

  bool _visible = true;
  double _lastPixels = 0;
  double _accumulated = 0;
  _Direction _accumulatingDirection = _Direction.none;

  ScrollController? _controller;
  VoidCallback? _listener;

  /// Whether the bar should currently be shown.
  bool get visible => _visible;

  /// Forces the bar visible and resets scroll-direction accumulation.
  void show() {
    _resetAccumulation();
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  /// Forces the bar hidden and resets scroll-direction accumulation.
  void hide() {
    _resetAccumulation();
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }

  void _resetAccumulation() {
    _accumulated = 0;
    _accumulatingDirection = _Direction.none;
  }

  /// Starts listening to [controller]. Call [detach] (or [dispose]) when the
  /// owner no longer needs this controller.
  void attach(ScrollController controller) {
    detach(_controller);
    _controller = controller;
    _listener = () => _onScrollChanged(controller);
    controller.addListener(_listener!);
  }

  /// Stops listening to [controller] (or the currently-attached controller
  /// when omitted).
  void detach([ScrollController? controller]) {
    final target = controller ?? _controller;
    final listener = _listener;
    if (target != null && listener != null) {
      target.removeListener(listener);
    }
    _controller = null;
    _listener = null;
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }

  void _onScrollChanged(ScrollController controller) {
    if (!controller.hasClients) return;
    final position = controller.position;

    // Short/non-scrollable content: never hide.
    if (position.maxScrollExtent <= minScrollExtentThreshold) {
      show();
      _lastPixels = position.pixels;
      return;
    }

    // Returning to (or starting at) the top: always show.
    if (position.pixels <= position.minScrollExtent) {
      show();
      _lastPixels = position.pixels;
      return;
    }

    // Overscroll (bounce past either edge): not a real scroll intent, leave
    // visibility as-is.
    if (position.outOfRange) {
      _lastPixels = position.pixels;
      return;
    }

    final delta = position.pixels - _lastPixels;
    _lastPixels = position.pixels;
    if (delta == 0) return;

    // Increasing pixels = content scrolling up under the finger (user
    // scrolling down the list) => hide. Decreasing = scrolling up => show.
    final direction = delta > 0 ? _Direction.hide : _Direction.show;
    if (_accumulatingDirection != direction) {
      _accumulatingDirection = direction;
      _accumulated = 0;
    }
    _accumulated += delta.abs();
    if (_accumulated < scrollThreshold) return;

    if (direction == _Direction.hide) {
      hide();
    } else {
      show();
    }
  }
}

enum _Direction { none, show, hide }
