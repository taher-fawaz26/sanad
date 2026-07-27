/// Our own connectivity model — `connectivity_plus` enums are never exposed.
enum ConnectivityStatus {
  /// Connected over Wi-Fi.
  wifi,

  /// Connected over a cellular/mobile data network.
  mobile,

  /// Connected over a wired ethernet network.
  ethernet,

  /// Connected over a VPN tunnel.
  vpn,

  /// Connected over a Bluetooth PAN.
  bluetooth,

  /// Connected over some other transport.
  other,

  /// No active network connection.
  none
  ;

  /// Whether this status represents an active connection of any kind.
  bool get isConnected => this != ConnectivityStatus.none;
}
