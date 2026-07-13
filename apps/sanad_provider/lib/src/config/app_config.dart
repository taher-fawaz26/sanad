import 'package:network/network.dart';

/// App-level API and environment configuration for sanad_provider.
///
/// The active environment is selected at build time via
/// `--dart-define=ENV=<dev|qa|stage|prod>`. Defaults to `dev`.
///
/// Example release build:
/// ```
/// flutter build apk --release --dart-define=ENV=prod
/// ```
abstract final class AppConfig {
  AppConfig._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// The active environment name (e.g. `dev`, `prod`).
  static String get environment => _env;

  /// Whether this build targets the production environment.
  static bool get isProduction => _env == 'prod';

  /// The network configuration used by the app.
  static NetworkConfig get network => switch (_env) {
    'prod' => const NetworkConfig(
      baseUrl: 'https://api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    'stage' => const NetworkConfig(
      baseUrl: 'https://stage-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    'qa' => const NetworkConfig(
      baseUrl: 'https://qa-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    _ => const NetworkConfig(
      baseUrl: 'https://dev-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
  };
}
