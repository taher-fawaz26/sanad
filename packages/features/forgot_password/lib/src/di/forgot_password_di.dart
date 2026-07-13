import 'package:core/core.dart';
import 'package:forgot_password/src/data/datasources/forgot_password_remote_datasource.dart';
import 'package:forgot_password/src/data/repositories/forgot_password_repository_impl.dart';
import 'package:forgot_password/src/domain/repositories/forgot_password_repository.dart';
import 'package:forgot_password/src/domain/usecases/request_forgot_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/reset_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:network/network.dart';

class ForgotPasswordDI {
  ForgotPasswordDI._();

  static void init() {
    sl
      ..registerLazySingleton<ForgotPasswordRemoteDataSource>(
        () => ForgotPasswordRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ForgotPasswordRepository>(
        () => ForgotPasswordRepositoryImpl(
          sl<ForgotPasswordRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => RequestForgotPasswordUseCase(sl<ForgotPasswordRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyForgotPasswordOtpUseCase(sl<ForgotPasswordRepository>()),
      )
      ..registerLazySingleton(
        () => ResetPasswordUseCase(sl<ForgotPasswordRepository>()),
      )
      ..registerFactory(
        () => ForgotPasswordBloc(
          requestForgotPasswordUseCase: sl<RequestForgotPasswordUseCase>(),
          verifyForgotPasswordOtpUseCase: sl<VerifyForgotPasswordOtpUseCase>(),
          resetPasswordUseCase: sl<ResetPasswordUseCase>(),
        ),
      );
  }
}
