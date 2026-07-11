import 'package:core/core.dart';
import 'package:forgot_password/src/data/datasources/forgot_password_remote_datasource.dart';
import 'package:forgot_password/src/domain/repositories/forgot_password_repository.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:fpdart/fpdart.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  const ForgotPasswordRepositoryImpl(this._remoteDataSource);

  final ForgotPasswordRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, void> requestForgotPassword(
    ForgotPasswordRequestParams params,
  ) =>
      _remoteDataSource.requestForgotPassword(identifier: params.identifier);

  @override
  TaskEither<Failure, void> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpParams params,
  ) =>
      _remoteDataSource.verifyForgotPasswordOtp(
        identifier: params.identifier,
        otp: params.otp,
      );

  @override
  TaskEither<Failure, void> resetPassword(ResetPasswordParams params) =>
      _remoteDataSource.resetPassword(
        identifier: params.identifier,
        password: params.password,
      );
}
