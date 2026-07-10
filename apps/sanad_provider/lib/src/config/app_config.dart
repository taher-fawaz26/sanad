import 'package:network/network.dart';

/// App-level API and environment configuration for sanad_provider.
abstract final class AppConfig {
  AppConfig._();

  /// The network configuration used by the app.
  static const NetworkConfig network = NetworkConfig(
    baseUrl: 'https://dev-api.trysanad.us/api/v1/',
    refreshTokenPath: 'auth/refresh',
  );
}
