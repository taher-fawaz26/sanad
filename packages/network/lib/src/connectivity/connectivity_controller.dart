import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:network/src/connectivity/connectivity_service.dart';

/// App-wide connectivity status — [Listenable] for UI / router listeners.
///
/// Does not own navigation. Apps listen and push/pop the offline route.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController(this._service) {
    unawaited(_init());
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  bool _isConnected = true;
  bool _initialized = false;

  bool get isConnected => _isConnected;
  bool get isInitialized => _initialized;

  Future<void> _init() async {
    _isConnected = await _service.isConnected();
    _initialized = true;
    notifyListeners();

    _subscription = _service.onConnectionChanged().listen((connected) {
      if (_isConnected == connected) return;
      _isConnected = connected;
      notifyListeners();
    });
  }

  /// Re-checks connectivity (e.g. Retry) and notifies if status changed.
  Future<bool> check() async {
    final connected = await _service.isConnected();
    if (_isConnected != connected || !_initialized) {
      _isConnected = connected;
      _initialized = true;
      notifyListeners();
    }
    return connected;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
