import 'package:analytics/src/observability_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Firebase-backed [ObservabilityService] implementation.
class FirebaseObservabilityService implements ObservabilityService {
  FirebaseObservabilityService({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
    FirebaseRemoteConfig? remoteConfig,
    FirebasePerformance? performance,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
       _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance,
       _performance = performance ?? FirebasePerformance.instance;

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  final FirebaseRemoteConfig _remoteConfig;
  final FirebasePerformance _performance;

  @override
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.fetchAndActivate();
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    // Touch performance SDK so it is linked at build time.
    await _performance.isPerformanceCollectionEnabled();
  }

  @override
  void logEvent(String name, {Map<String, dynamic>? params}) {
    _analytics.logEvent(
      name: name,
      parameters: params?.map((k, v) => MapEntry(k, v as Object)),
    );
  }

  @override
  void logError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
    bool fatal = false,
  }) {
    if (context != null) {
      for (final entry in context.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    if (fatal) {
      _crashlytics.recordError(error, stackTrace, fatal: true);
    } else {
      _crashlytics.recordError(error, stackTrace);
    }
  }

  @override
  void setUser(String? userId, {Map<String, dynamic>? properties}) {
    if (userId != null) {
      _analytics.setUserId(id: userId);
      _crashlytics.setUserIdentifier(userId);
    }
    if (properties != null) {
      for (final entry in properties.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
  }

  @override
  void logPageView(String pageName) {
    _analytics.logScreenView(screenName: pageName);
  }

  @override
  Future<T?> getRemoteValue<T>(String key, T defaultValue) async {
    if (T == bool) {
      return _remoteConfig.getBool(key) as T? ?? defaultValue;
    }
    if (T == int) {
      return _remoteConfig.getInt(key) as T? ?? defaultValue;
    }
    if (T == double) {
      return _remoteConfig.getDouble(key) as T? ?? defaultValue;
    }
    if (T == String) {
      final value = _remoteConfig.getString(key);
      return (value.isEmpty ? defaultValue : value) as T;
    }
    return defaultValue;
  }

  @override
  Future<bool> isFeatureEnabled(String flag) async {
    await _remoteConfig.fetchAndActivate();
    return _remoteConfig.getBool(flag);
  }
}
