import 'package:config/config.dart';

import 'package:flavors/src/flavor_config.dart';

/// Pre-built FlavorConfig instances for each deployment environment.
///
/// Apps pick the right constant in their `main_<flavor>.dart`
/// entry-points and register it with GetIt before any other DI
/// initialisation.
abstract final class Flavors {
  // ── Dev ──────────────────────────────────────────────────────────────────
  /// [FlavorConfig] for the development environment.
  static const FlavorConfig dev = FlavorConfig(
    firebaseProjectId: 'sand-dev',
    build: BuildConfig(
      environment: Environment.dev,
      appName: 'Sand Dev',
      appVersion: '1.0.0',
      buildNumber: 1,
    ),
    urls: AppUrls(
      apiBaseUrl: 'https://dev-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    flags: FeatureFlags(
      enableAnalytics: false,
      enableCrashReporting: false,
    ),
  );

  // ── QA ───────────────────────────────────────────────────────────────────
  /// [FlavorConfig] for the QA environment.
  static const FlavorConfig qa = FlavorConfig(
    firebaseProjectId: 'sand-qa',
    build: BuildConfig(
      environment: Environment.qa,
      appName: 'Sand QA',
      appVersion: '1.0.0',
      buildNumber: 1,
    ),
    urls: AppUrls(
      apiBaseUrl: 'https://qa-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    flags: FeatureFlags(

    ),
  );

  // ── Stage ─────────────────────────────────────────────────────────────────
  /// [FlavorConfig] for the staging environment.
  static const FlavorConfig stage = FlavorConfig(
    firebaseProjectId: 'sand-stage',
    build: BuildConfig(
      environment: Environment.stage,
      appName: 'Sand Stage',
      appVersion: '1.0.0',
      buildNumber: 1,
    ),
    urls: AppUrls(
      apiBaseUrl: 'https://stage-api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    flags: FeatureFlags(
      enableBiometricLogin: true,
    ),
  );

  // ── Production ───────────────────────────────────────────────────────────
  /// [FlavorConfig] for the production environment.
  static const FlavorConfig production = FlavorConfig(
    firebaseProjectId: 'sand-production',
    build: BuildConfig(
      environment: Environment.production,
      appName: 'Sand',
      appVersion: '1.0.0',
      buildNumber: 1,
    ),
    urls: AppUrls(
      apiBaseUrl: 'https://api.trysanad.us/api/v1/',
      refreshTokenPath: 'auth/refresh',
    ),
    flags: FeatureFlags(
      enableBiometricLogin: true,
    ),
  );
}
