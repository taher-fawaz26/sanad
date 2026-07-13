import 'package:config/config.dart';
import 'package:meta/meta.dart';

/// Full configuration bundle for one flavor.
///
/// Each app creates one instance per flavor in its
/// `main_<flavor>.dart`.
/// Inject via GetIt so packages can read URLs / feature flags without
/// knowing which app they're running inside.
@immutable
class FlavorConfig {
  /// Creates a [FlavorConfig] with the given build, URL, flag, and
  /// Firebase project settings.
  const FlavorConfig({
    required this.build,
    required this.urls,
    required this.flags,
    required this.firebaseProjectId,
  });

  /// Build-time metadata (environment, version, build number).
  final BuildConfig build;

  /// Base URLs used by the network layer for this flavor.
  final AppUrls urls;

  /// Feature flags that toggle optional capabilities for this flavor.
  final FeatureFlags flags;

  /// Firebase project ID associated with this flavor.
  final String firebaseProjectId;

  /// The [Environment] derived from [build].
  Environment get environment => build.environment;

  /// Whether this flavor is running in the production environment.
  bool get isProduction => environment.isProduction;
}
