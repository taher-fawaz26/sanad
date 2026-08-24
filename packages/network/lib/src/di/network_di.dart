import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:network/src/client/api_client_impl.dart';
import 'package:network/src/client/base_api_client.dart';
import 'package:network/src/client/secure_dio_client.dart';
import 'package:network/src/config/text_optimization_api_config.dart';
import 'package:network/src/connectivity/connectivity_controller.dart';
import 'package:network/src/connectivity/connectivity_service.dart';
import 'package:network/src/connectivity/connectivity_service_impl.dart';
import 'package:network/src/connectivity/network_guard.dart';
import 'package:network/src/interceptors/accept_language_interceptor.dart';
import 'package:network/src/interceptors/auth_interceptor.dart';
import 'package:network/src/interceptors/logging_interceptor.dart';
import 'package:network/src/interceptors/retry_on_timeout_interceptor.dart';
import 'package:network/src/interceptors/timeout_error_interceptor.dart';
import 'package:network/src/network_config.dart';
import 'package:network/src/token/token_manager.dart';
import 'package:network/src/token/token_manager_impl.dart';

/// Registers the shared network stack against the global service locator.
///
/// Both apps used to duplicate ~60 lines of Dio + TokenManager +
/// interceptor + connectivity wiring in their DI. This helper is the single
/// source of truth. Apps call it once from `configureDependencies` and pass:
///
/// * [networkConfig] — base URL, timeouts, `refreshTokenPath` (per-app).
/// * [logger] — the app's shared logger for the [LoggingInterceptor].
/// * [resolveLanguageCode] — pulls the current UI language for the
///   `Accept-Language` header, without coupling `network` to the app's
///   translation bloc.
/// * [onUnauthorized] — invoked when refresh fails; the app forces logout
///   through its own `AuthStatusNotifier` (kept behind a callback so
///   `network` never depends on `auth`).
///
/// Preconditions: `TokenStorage` must already be registered — apps own the
/// concrete storage (secure vs test double) so `network` doesn't reach into
/// `storage`.
///
/// Registers under `sl`:
/// * `Dio` named `'rawDio'` (no auth interceptor)
/// * `TokenManager` (initialized before the future completes)
/// * `ConnectivityService` / `ConnectivityController` / `NetworkGuard`
/// * `Dio` named `'authDio'` (with auth + retry + logging)
/// * `SecureDioClient`, `BaseApiClient`
///
/// The higher-level `SessionManager` (holding the full [AuthSessionEntity])
/// lives in the `auth` package and is registered by `AuthDI.init` — network
/// deliberately does not know about auth-domain types.
abstract final class NetworkDI {
  NetworkDI._();

  /// `GetIt` instance name for the [BaseApiClient] wired to the third-party
  /// text-optimization host ([TextOptimizationApiConfig]) — deliberately a
  /// separate, unauthenticated client so the user's session token is never
  /// sent to that external host. Consumed by the `text_optimization` package.
  static const textOptimizationApiClientInstanceName =
      'textOptimizationApiClient';

  static Future<void> init({
    required NetworkConfig networkConfig,
    required Logger logger,
    required String Function() resolveLanguageCode,
    required void Function() onUnauthorized,
  }) async {
    sl
      ..registerLazySingleton<NetworkConfig>(() => networkConfig)
      // Raw Dio — no AuthInterceptor. Used by TokenManagerImpl to refresh
      // without triggering itself.
      ..registerLazySingleton<Dio>(
        () {
          final config = sl<NetworkConfig>();
          final dio = Dio(config.dioBaseOptions);
          dio.interceptors.add(LoggingInterceptor(logger: logger));
          return dio;
        },
        instanceName: 'rawDio',
      )
      ..registerLazySingleton<TokenManager>(
        () => TokenManagerImpl(
          sl<Dio>(instanceName: 'rawDio'),
          sl<TokenStorage>(),
          sl<NetworkConfig>(),
        ),
      );

    await sl<TokenManager>().init();

    sl
      ..registerLazySingleton<ConnectivityService>(ConnectivityServiceImpl.new)
      ..registerLazySingleton(
        () => ConnectivityController(sl<ConnectivityService>()),
      )
      ..registerLazySingleton(() => NetworkGuard(sl<ConnectivityService>()))
      // Authenticated Dio — used by every feature.
      ..registerLazySingleton<Dio>(
        () {
          final config = sl<NetworkConfig>();
          final dio = Dio(config.dioBaseOptions);
          dio.interceptors.addAll([
            AcceptLanguageInterceptor(
              resolveLanguageCode: resolveLanguageCode,
            ),
            AuthInterceptor(
              dio: dio,
              tokenManager: sl<TokenManager>(),
              refreshTokenPath: config.refreshTokenPath,
              onUnauthorized: onUnauthorized,
            ),
            RetryOnTimeoutInterceptor(dio: dio),
            TimeoutErrorInterceptor(),
            LoggingInterceptor(logger: logger),
          ]);
          return dio;
        },
        instanceName: 'authDio',
      )
      ..registerLazySingleton<SecureDioClient>(
        () => SecureDioClient(sl<Dio>(instanceName: 'authDio')),
      )
      ..registerLazySingleton<BaseApiClient>(
        () => ApiClientImpl(sl<SecureDioClient>(), sl<NetworkGuard>()),
      )
      // Text-optimization Dio — a separate unauthenticated client scoped to
      // the fixed third-party host (SAN-578). No AuthInterceptor: this host
      // is not the Sanad backend and must never receive the session token.
      ..registerLazySingleton<Dio>(
        () {
          final dio = Dio(
            BaseOptions(
              baseUrl: TextOptimizationApiConfig.baseUrl,
              connectTimeout: TextOptimizationApiConfig.connectTimeout,
              receiveTimeout: TextOptimizationApiConfig.receiveTimeout,
              headers: const {'Accept': 'application/json'},
            ),
          );
          dio.interceptors.addAll([
            TimeoutErrorInterceptor(),
            LoggingInterceptor(logger: logger),
          ]);
          return dio;
        },
        instanceName: 'textOptimizationDio',
      )
      ..registerLazySingleton<SecureDioClient>(
        () => SecureDioClient(sl<Dio>(instanceName: 'textOptimizationDio')),
        instanceName: 'textOptimizationSecureDioClient',
      )
      ..registerLazySingleton<BaseApiClient>(
        () => ApiClientImpl(
          sl<SecureDioClient>(instanceName: 'textOptimizationSecureDioClient'),
          sl<NetworkGuard>(),
        ),
        instanceName: textOptimizationApiClientInstanceName,
      );
  }
}
