import 'package:deep_linking/deep_linking.dart';
import 'package:network/network.dart';

/// App-level API and environment configuration for sanad_client.
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

  /// Trusted incoming-link sources for this app: the App Links / Universal
  /// Links host for the active environment, plus the `sanadclient://`
  /// custom scheme (registered on every environment for QA/testing before a
  /// domain is verified).
  static DeepLinkConfig get deepLinkConfig => switch (_env) {
    'prod' => const DeepLinkConfig(
      schemes: {'sanadclient'},
      hosts: {'links.trysanad.us'},
    ),
    'stage' => const DeepLinkConfig(
      schemes: {'sanadclient'},
      hosts: {'stage-links.trysanad.us'},
    ),
    'qa' => const DeepLinkConfig(
      schemes: {'sanadclient'},
      hosts: {'qa-links.trysanad.us'},
    ),
    _ => const DeepLinkConfig(
      schemes: {'sanadclient'},
      hosts: {'dev-links.trysanad.us'},
    ),
  };
}
