import 'dart:async';

import 'package:core/core.dart';

/// Broadcast signal emitted when the in-app language changes.
/// Multiple calls within `coalesceWindow` are coalesced into one tick.
///
/// Implements [LocaleChangeBus] so that [BaseRequestBloc] in sand_core
/// can subscribe without a circular dependency.
class AppLocaleRefreshBus implements LocaleChangeBus {
  AppLocaleRefreshBus({
    Duration coalesceWindow = const Duration(milliseconds: 200),
  })  : _controller = StreamController<int>.broadcast(),
        _coalesceWindow = coalesceWindow;

  final StreamController<int> _controller;
  final Duration _coalesceWindow;
  Timer? _pending;
  int _generation = 0;

  /// Raw integer stream (generation counter). Use [changes] for the
  /// [LocaleChangeBus] contract.
  Stream<int> get stream => _controller.stream;

  @override
  Stream<void> get changes => _controller.stream;

  void notifyLocaleChanged() {
    if (_controller.isClosed) return;
    _pending?.cancel();
    _pending = Timer(_coalesceWindow, () {
      if (!_controller.isClosed) _controller.add(++_generation);
    });
  }

  Future<void> dispose() async {
    _pending?.cancel();
    _pending = null;
    await _controller.close();
  }
}
