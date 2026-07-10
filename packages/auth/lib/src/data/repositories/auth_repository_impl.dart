import 'package:auth/src/data/datasources/auth_local_datasource.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/models/requests/login_model_request.dart';
import 'package:auth/src/data/models/requests/register_model_request.dart';
import 'package:auth/src/data/models/requests/validate_otp_request.dart';
import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  TaskEither<Failure, LoginResponseEntity> login(LoginParams params) {
    final model = LoginModelRequest(
      identifier: params.identifier,
      password: params.password,
    );
    return _remoteDataSource
        .login(model)
        .map((r) => r.toEntity())
        .chainFirst((entity) => _localDataSource.saveUser(entity.user));
  }

  @override
  TaskEither<Failure, void> logout() =>
      _remoteDataSource.logout().flatMap((_) => _localDataSource.clearUser());

  @override
  TaskEither<Failure, void> register(RegisterParams params) =>
      _remoteDataSource.register(
        RegisterModelRequest(
          identifier: params.identifier,
          password: params.password,
          type: params.type,
        ),
      );

  @override
  TaskEither<Failure, UserEntity?> checkSignInStatus() =>
      _localDataSource.checkSignInStatus();

  @override
  TaskEither<Failure, LoginResponseEntity> validateOtp(
    ValidateOtpParams params,
  ) =>
      _remoteDataSource
          .validateOtp(
            ValidateOtpRequest(
              identifier: params.identifier,
              otp: params.otp,
            ),
          )
          .map((r) => r.toEntity())
          .chainFirst((entity) => _localDataSource.saveUser(entity.user));

  @override
  TaskEither<Failure, void> requestForgotPassword(
    ForgotPasswordRequestParams params,
  ) =>
      _remoteDataSource.requestForgotPassword(
        identifier: params.identifier,
      );

  @override
  TaskEither<Failure, void> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpParams params,
  ) =>
      _remoteDataSource.validateAuthOtpForgotPassword(
        identifier: params.identifier,
        otp: params.otp,
      );

  @override
  TaskEither<Failure, void> resetPassword(ResetPasswordParams params) =>
      _remoteDataSource.resetPassword(
        identifier: params.identifier,
        password: params.password,
      );

  @override
  TaskEither<Failure, void> resendOtp(ResendOtpParams params) =>
      _remoteDataSource.resendOtp(
        identifier: params.identifier,
        purpose: params.purpose,
      );

  @override
  TaskEither<Failure, void> deleteAccount(DeleteAccountParams params) =>
      _remoteDataSource
          .deleteAccount(userSub: params.userSub)
          .flatMap((_) => _localDataSource.clearUser());
}
