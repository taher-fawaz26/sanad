import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device/src/domain/enums/connectivity_status.dart';

/// Wraps `connectivity_plus`. No plugin type escapes this class.
class ConnectivityProvider {
  ConnectivityProvider([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<ConnectivityStatus> currentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _reduce(results);
  }

  Stream<ConnectivityStatus> onStatusChanged() {
    return _connectivity.onConnectivityChanged.map(_reduce);
  }

  /// `connectivity_plus` returns a list (a device can have several active
  /// interfaces). We collapse it to the single most relevant status.
  ConnectivityStatus _reduce(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectivityStatus.none;

    // Priority order: a "real" transport wins over none/other.
    for (final preferred in const [
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
      ConnectivityResult.mobile,
      ConnectivityResult.vpn,
      ConnectivityResult.bluetooth,
      ConnectivityResult.satellite,
      ConnectivityResult.other,
    ]) {
      if (results.contains(preferred)) return _map(preferred);
    }
    return ConnectivityStatus.none;
  }

  ConnectivityStatus _map(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => ConnectivityStatus.wifi,
      ConnectivityResult.mobile => ConnectivityStatus.mobile,
      ConnectivityResult.ethernet => ConnectivityStatus.ethernet,
      ConnectivityResult.vpn => ConnectivityStatus.vpn,
      ConnectivityResult.bluetooth => ConnectivityStatus.bluetooth,
      // `satellite` (connectivity_plus 7+) has no dedicated domain status;
      // surface it as a generic "other" active connection.
      ConnectivityResult.satellite => ConnectivityStatus.other,
      ConnectivityResult.other => ConnectivityStatus.other,
      ConnectivityResult.none => ConnectivityStatus.none,
    };
  }
}
