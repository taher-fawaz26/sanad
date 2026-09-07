import 'package:config/config.dart';
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

  /// Build-time feature toggles.
  ///
  /// `enableBiometricLogin` is the kill switch for the local app-lock gate:
  /// with it off the gate stays open, the Security row is hidden, and no
  /// biometric prompt is ever raised. It is on in every environment — the
  /// switch exists so the feature can be disabled in a hotfix build without
  /// reverting code, not to stage a rollout.
  static FeatureFlags get featureFlags => const FeatureFlags(
    enableBiometricLogin: true,
  );

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

  /// The AI agent's streaming-chat endpoint (`POST` + `text/event-stream`).
  ///
  /// The current real transport. Temporary: the agent team cannot yet supply a
  /// complete WebSocket contract, and this endpoint already emits the SANAD UI
  /// Protocol v1 envelope verbatim. [aiAgentSocketUrl] is retained as the
  /// reference transport, reachable with `?transport=ws`.
  ///
  /// Only the dev host has been exercised against a live server. The other
  /// environments follow the same naming, but the chat route itself is
  /// registered `if (!kReleaseMode)`, so a production build never opens this
  /// connection — confirm the host with the agent team before that changes.
  static String get aiAgentStreamUrl => switch (_env) {
    'prod' => 'https://agent.trysanad.us/user-agent/chat/stream',
    'stage' => 'https://agent-stage.trysanad.us/user-agent/chat/stream',
    'qa' => 'https://agent-qa.trysanad.us/user-agent/chat/stream',
    _ => 'https://agent-dev.trysanad.us/user-agent/chat/stream',
  };

  /// The AI agent's chat WebSocket endpoint.
  ///
  /// Kept as the reference transport behind `?transport=ws`; [aiAgentStreamUrl]
  /// is what a normal visit to the chat now uses.
  ///
  /// TLS-only: the server rejects `ws://` outright (the handshake fails and
  /// the socket closes 1006), so every environment is `wss://`.
  ///
  /// Only the dev host has been exercised against a live server. The other
  /// environments follow the same naming, but the chat route itself is
  /// registered `if (!kReleaseMode)`, so a production build never opens this
  /// connection — confirm the host with the agent team before that changes.
  static String get aiAgentSocketUrl => switch (_env) {
    'prod' => 'wss://agent.trysanad.us/agent/chat/ws',
    'stage' => 'wss://agent-stage.trysanad.us/agent/chat/ws',
    'qa' => 'wss://agent-qa.trysanad.us/agent/chat/ws',
    _ => 'wss://agent-dev.trysanad.us/agent/chat/ws',
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
