import 'package:app_logger/app_logger.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/config/app_config.dart';
import 'package:storage/storage.dart';

late final ModuleRegistry moduleRegistry;

/// Registers all application-level dependencies with the service locator.
Future<void> configureDependencies() async {
  // ── Storage ──────────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton<HiveEncryptionKeyManager>(
      () => HiveEncryptionKeyManager(sl<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<HiveLocalStorage>(
      () => HiveLocalStorage(
        encryptionKeyManager: sl<HiveEncryptionKeyManager>(),
      ),
    )
    ..registerLazySingleton<TokenStorage>(
      () => TokenStorageImpl(sl<FlutterSecureStorage>()),
    )
    // ── Localization & Theme ─────────────────────────────────────────────────
    ..registerLazySingleton(AppLocaleRefreshBus.new)
    ..registerLazySingleton<LocaleChangeBus>(sl.call<AppLocaleRefreshBus>)
    ..registerLazySingleton(TranslateBloc.new)
    ..registerLazySingleton(ThemeBloc.new)
    // ── Auth status ──────────────────────────────────────────────────────────
    ..registerLazySingleton(AuthStatusNotifier.new)
    // ── Network config ───────────────────────────────────────────────────────
    ..registerLazySingleton<NetworkConfig>(() => AppConfig.network)
    // ── Raw Dio (no AuthInterceptor — used by TokenManagerImpl only) ─────────
    ..registerLazySingleton<Dio>(
      () {
        final config = sl<NetworkConfig>();
        final dio = Dio(config.dioBaseOptions);
        dio.interceptors.add(LoggingInterceptor());
        return dio;
      },
      instanceName: 'rawDio',
    )
    // ── Token manager ────────────────────────────────────────────────────────
    ..registerLazySingleton<TokenManager>(
      () => TokenManagerImpl(
        sl<Dio>(instanceName: 'rawDio'),
        sl<TokenStorage>(),
        sl<NetworkConfig>(),
      ),
    );
  await sl<TokenManager>().init();

  // ── Session manager ──────────────────────────────────────────────────────
  sl
    ..registerLazySingleton(() => SessionManager(sl<TokenManager>()))
    // ── Connectivity ─────────────────────────────────────────────────────────
    ..registerLazySingleton<ConnectivityService>(ConnectivityServiceImpl.new)
    ..registerLazySingleton(() => NetworkGuard(sl<ConnectivityService>()))
    // ── Authenticated Dio (with AuthInterceptor) ─────────────────────────────
    ..registerLazySingleton<Dio>(
      () {
        final config = sl<NetworkConfig>();
        final dio = Dio(config.dioBaseOptions);

        dio.interceptors.addAll([
          AcceptLanguageInterceptor(
            resolveLanguageCode: () =>
                sl<TranslateBloc>().state.languageCode,
          ),
          AuthInterceptor(
            dio: dio,
            tokenManager: sl<TokenManager>(),
            refreshTokenPath: config.refreshTokenPath,
            onUnauthorized: () =>
                sl<AuthStatusNotifier>().update(AuthStatus.unauthenticated),
          ),
          RetryOnTimeoutInterceptor(dio: dio),
          TimeoutErrorInterceptor(),
          LoggingInterceptor(),
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
    );

  // ── Feature modules ────────────────────────────────────────────────────────
  moduleRegistry = ModuleRegistry([
    AuthModule(),
    OtpModule(),
    ForgotPasswordModule(),
    BranchesModule(),
  ]);
  await moduleRegistry.initAll();

  appLogger.i('[AppDI] Dependency injection configured for sanad_provider');
}
