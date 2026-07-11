import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/data/datasources/auth_local_datasource.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/repositories/auth_repository_impl.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/login_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/register_usecase.dart';
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
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          sl<AuthRemoteDataSource>(),
          sl<AuthLocalDataSource>(),
        ),
      )
      ..registerLazySingleton(() => AuthLoginUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(() => AuthLogoutUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(() => DeleteAccountUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(() => AuthRegisterUseCase(sl<AuthRepository>()))
      ..registerLazySingleton(
        () => AuthCheckSignInStatusUseCase(sl<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => AuthBloc(
          loginUseCase: sl<AuthLoginUseCase>(),
          logoutUseCase: sl<AuthLogoutUseCase>(),
          deleteAccountUseCase: sl<DeleteAccountUseCase>(),
          registerUseCase: sl<AuthRegisterUseCase>(),
          sessionManager: sl<SessionManager>(),
          checkSignInStatusUseCase: sl<AuthCheckSignInStatusUseCase>(),
          authStatusNotifier: sl<AuthStatusNotifier>(),
        ),
      );
  }
}
