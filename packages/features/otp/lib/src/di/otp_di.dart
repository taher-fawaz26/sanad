import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:otp/src/data/datasources/otp_remote_datasource.dart';
import 'package:otp/src/data/repositories/otp_repository_impl.dart';
import 'package:otp/src/domain/repositories/otp_repository.dart';
import 'package:otp/src/domain/usecases/resend_otp_usecase.dart';
import 'package:otp/src/domain/usecases/validate_otp_usecase.dart';
import 'package:otp/src/presentation/bloc/otp_bloc.dart';

class OtpDI {
  OtpDI._();

  static void init() {
    sl
      ..registerLazySingleton<OtpRemoteDataSource>(
        () => OtpRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<OtpRepository>(
        () => OtpRepositoryImpl(
          sl<OtpRemoteDataSource>(),
          sl<AuthLocalDataSource>(),
        ),
      )
      ..registerLazySingleton(() => ValidateOtpUseCase(sl<OtpRepository>()))
      ..registerLazySingleton(() => ResendOtpUseCase(sl<OtpRepository>()))
      ..registerFactory(
        () => OtpBloc(
          validateOtpUseCase: sl<ValidateOtpUseCase>(),
          resendOtpUseCase: sl<ResendOtpUseCase>(),
          sessionManager: sl<SessionManager>(),
          authStatusNotifier: sl<AuthStatusNotifier>(),
        ),
      );
  }
}
