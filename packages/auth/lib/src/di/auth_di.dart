import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/authorization/authorization_signal.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/repositories/auth_repository_impl.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/get_client_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_client_otp_usecase.dart';
import 'package:auth/src/domain/usecases/request_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/request_signup_otp_usecase.dart';
import 'package:auth/src/domain/usecases/resend_otp_usecase.dart';
import 'package:auth/src/domain/usecases/social_login_usecase.dart';
import 'package:auth/src/domain/usecases/social_signup_usecase.dart';
import 'package:auth/src/domain/usecases/update_client_profile_usecase.dart';
import 'package:auth/src/domain/usecases/verify_client_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_signup_otp_usecase.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:auth/src/session/session_repository.dart';
import 'package:auth/src/session/session_storage.dart';
import 'package:authorization/authorization.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

class AuthDI {
  AuthDI._();

  /// [onSessionBoundary] — invoked whenever a session begins or ends (login,
  /// logout, 401-refresh-failure, account replacement). Kept behind a
  /// callback so `auth` never depends on `core`'s `ModuleRegistry`; the app
  /// composition root wires it to `moduleRegistry.disposeAll()` — see
  /// `AuthModule`'s matching constructor parameter.
  static void init({void Function()? onSessionBoundary}) {
    sl
      // ── Session layer ─────────────────────────────────────────────────────
      // Owns the full AuthSessionEntity (tokens + user + profile +
      // accountSettings + permissions). Replaces the old token-only
      // SessionManager that used to live in `network`.
      ..registerLazySingleton<SessionCache>(SessionCache.new)
      ..registerLazySingleton<SessionStorage>(
        () => SessionStorage(sl<HiveLocalStorage>()),
      )
      ..registerLazySingleton<SessionRepository>(
        () => SessionRepository(
          cache: sl<SessionCache>(),
          storage: sl<SessionStorage>(),
          tokenManager: sl<TokenManager>(),
        ),
      )
      ..registerLazySingleton<SessionManager>(
        () => SessionManager(
          repository: sl<SessionRepository>(),
          cache: sl<SessionCache>(),
          tokenManager: sl<TokenManager>(),
          authStatusNotifier: sl<AuthStatusNotifier>(),
          onSessionBoundary: onSessionBoundary,
        ),
      )
      // ── Authorization ─────────────────────────────────────────────────────
      // The AuthorizationReader port (package:authorization) implemented over
      // the same SessionCache — not a second cache or a new BLoC. See
      // AuthorizationSignal's doc comment.
      ..registerLazySingleton<AuthorizationReader>(
        () => AuthorizationSignal(sl<SessionCache>()),
      )
      // ── Data sources ──────────────────────────────────────────────────────
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<GoogleAuthDataSource>(
        () => GoogleAuthDataSourceImpl(apiClient: sl<BaseApiClient>()),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          sl<AuthRemoteDataSource>(),
          sl<GoogleAuthDataSource>(),
        ),
      )
      // ── Use cases ────────────────────────────────────────────────────────
      ..registerLazySingleton(
        () => RequestSignupOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => VerifySignupOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => RequestLoginOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyLoginOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(() => ResendOtpUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(
        () => GetResendInfoUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(() => SocialSignupUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(() => SocialLoginUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(
        () => GetCurrentUserUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(() => AuthLogoutUseCase(sl<AuthRepository>()))
      // ── Unified client sign-in use cases ─────────────────────────────────
      ..registerLazySingleton(
        () => RequestClientOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => GetClientResendInfoUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyClientOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateClientProfileUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => AuthCheckSignInStatusUseCase(sl<SessionManager>()),
      )
      ..registerFactory(
        () => AuthBloc(
          requestSignupOtpUseCase: sl<RequestSignupOtpUseCase>(),
          requestLoginOtpUseCase: sl<RequestLoginOtpUseCase>(),
          resendOtpUseCase: sl<ResendOtpUseCase>(),
          getResendInfoUseCase: sl<GetResendInfoUseCase>(),
          logoutUseCase: sl<AuthLogoutUseCase>(),
          sessionManager: sl<SessionManager>(),
          checkSignInStatusUseCase: sl<AuthCheckSignInStatusUseCase>(),
          authStatusNotifier: sl<AuthStatusNotifier>(),
          socialSignupUseCase: sl<SocialSignupUseCase>(),
          socialLoginUseCase: sl<SocialLoginUseCase>(),
          getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
        ),
      );
  }
}
