import 'package:analytics/src/observability_service.dart';

/// No-op implementation for tests and offline development.
class NoopObservabilityService implements ObservabilityService {
  @override
  Future<void> initialize() async {}

  @override
  void logEvent(String name, {Map<String, dynamic>? params}) {}

  @override
  void logError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
    bool fatal = false,
  }) {}

  @override
  void setUser(String? userId, {Map<String, dynamic>? properties}) {}

  @override
  void logPageView(String pageName) {}

  @override
  Future<T?> getRemoteValue<T>(String key, T defaultValue) async =>
      defaultValue;

  @override
  Future<bool> isFeatureEnabled(String flag) async => false;
}
