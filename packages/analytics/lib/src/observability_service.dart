/// Unified observability contract for crash reporting, analytics,
/// performance, logging, remote config, and feature flags.
abstract interface class ObservabilityService {
  /// Initialise SDKs — call once before routing.
  Future<void> initialize();

  /// Log a custom analytics event.
  void logEvent(String name, {Map<String, dynamic>? params});

  /// Log a non-fatal or fatal error with stack trace.
  void logError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
    bool fatal = false,
  });

  /// Associate events/errors with a user (never pass PII).
  void setUser(String? userId, {Map<String, dynamic>? properties});

  /// Log a screen/page view.
  void logPageView(String pageName);

  /// Read a remote config value with [defaultValue] fallback.
  Future<T?> getRemoteValue<T>(String key, T defaultValue);

  /// Check whether a remote feature flag is enabled.
  Future<bool> isFeatureEnabled(String flag);
}
