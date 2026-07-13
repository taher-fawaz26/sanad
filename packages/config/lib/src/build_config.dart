import 'package:config/src/environment.dart';
import 'package:meta/meta.dart';

/// Immutable build-time configuration.
/// Instantiate once per flavor and expose via the DI container.
@immutable
class BuildConfig {
  /// Creates a [BuildConfig] with the given environment and app metadata.
  const BuildConfig({
    required this.environment,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    this.sentryDsn,
    this.mixpanelToken,
  });

  /// The deployment environment this build targets.
  final Environment environment;

  /// The human-readable application name.
  final String appName;

  /// The semantic version string (e.g. `1.2.3`).
  final String appVersion;

  /// The monotonically increasing build number.
  final int buildNumber;

  /// The Sentry DSN used for crash reporting, if configured.
  final String? sentryDsn;

  /// The Mixpanel project token used for analytics, if configured.
  final String? mixpanelToken;

  /// Whether this is a debug (dev) build.
  bool get isDebug => environment.isDev;

  /// Whether this is a production release build.
  bool get isRelease => environment.isProduction;
}
