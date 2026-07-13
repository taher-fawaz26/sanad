/// Abstract connectivity service — no connectivity_plus types leak through.
abstract class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> onConnectionChanged();
}
