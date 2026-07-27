import 'package:device/src/domain/enums/connectivity_status.dart';

/// Reports and streams the device's network connectivity.
abstract class ConnectivityService {
  /// The current connectivity status.
  Future<ConnectivityStatus> currentStatus();

  /// Whether the device currently has any active connection.
  Future<bool> isConnected();

  /// Emits a new [ConnectivityStatus] whenever connectivity changes.
  Stream<ConnectivityStatus> onStatusChanged();
}
