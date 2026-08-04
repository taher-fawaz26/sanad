import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/data/datasources/auth_local_datasource.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/repositories/auth_repository_impl.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:auth/src/domain/usecases/validate_email_usecase.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

class AuthDI {
  AuthDI._();

  static void init() {
    sl
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(
          sl<TokenManager>(),
          sl<HiveLocalStorage>(),
        ),
      )
      ..registerLazySingleton<GoogleAuthDataSource>(
        () => GoogleAuthDataSourceImpl(apiClient: sl<BaseApiClient>()),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          sl<AuthRemoteDataSource>(),
          sl<AuthLocalDataSource>(),
          sl<GoogleAuthDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => RequestEmailOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyEmailOtpUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(() => AuthLogoutUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(() => DeleteAccountUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(
        () => AuthCheckSignInStatusUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => SignInWithGoogleUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => ValidateEmailUseCase(sl<AuthRepository>()),
      )
      ..registerFactory(
        () => AuthBloc(
          requestOtpUseCase: sl<RequestEmailOtpUseCase>(),
          logoutUseCase: sl<AuthLogoutUseCase>(),
          deleteAccountUseCase: sl<DeleteAccountUseCase>(),
          sessionManager: sl<SessionManager>(),
          checkSignInStatusUseCase: sl<AuthCheckSignInStatusUseCase>(),
          authStatusNotifier: sl<AuthStatusNotifier>(),
          signInWithGoogleUseCase: sl<SignInWithGoogleUseCase>(),
          validateEmailUseCase: sl<ValidateEmailUseCase>(),
        ),
      );
  }
}
