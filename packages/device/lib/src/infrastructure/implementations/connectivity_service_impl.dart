import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:device/src/domain/services/connectivity_service.dart';
import 'package:device/src/infrastructure/providers/connectivity_provider.dart';

class ConnectivityServiceImpl implements ConnectivityService {
  const ConnectivityServiceImpl(this._provider);

  final ConnectivityProvider _provider;

  @override
  Future<ConnectivityStatus> currentStatus() => _provider.currentStatus();

  @override
  Future<bool> isConnected() async => (await currentStatus()).isConnected;

  @override
  Stream<ConnectivityStatus> onStatusChanged() => _provider.onStatusChanged();
}
