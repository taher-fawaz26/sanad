import 'package:meta/meta.dart';

/// Feature toggles that can differ per environment or build.
///
/// Instantiate once in AppConfig and inject via your DI container.
@immutable
class FeatureFlags {
  /// Creates a [FeatureFlags] instance with sensible defaults.
  const FeatureFlags({
    this.enableOtpVerification = true,
    this.enableBiometricLogin = false,
    this.enablePushNotifications = true,
    this.enableCrashReporting = true,
    this.enableAnalytics = true,
    this.enableGoogleSignIn = false,
    this.enableAppleSignIn = false,
  });

  /// Whether OTP-based phone verification is enabled.
  final bool enableOtpVerification;

  /// Whether biometric (fingerprint / Face ID) login is enabled.
  final bool enableBiometricLogin;

  /// Whether push notifications are enabled.
  final bool enablePushNotifications;

  /// Whether crash reporting (e.g. Sentry) is enabled.
  final bool enableCrashReporting;

  /// Whether analytics event tracking is enabled.
  final bool enableAnalytics;

  /// Whether Sign in with Google is enabled.
  final bool enableGoogleSignIn;

  /// Whether Sign in with Apple is enabled.
  final bool enableAppleSignIn;
}

/// Remote Config boolean flag keys — used by [ObservabilityService.isFeatureEnabled].
abstract final class RemoteFeatureFlagKeys {
  static const String newOrdersFlow = 'ff_new_orders_flow';
  static const String multiLanguageSupport = 'ff_multi_language';
}
