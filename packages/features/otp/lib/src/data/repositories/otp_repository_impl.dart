import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/data/datasources/otp_remote_datasource.dart';
import 'package:otp/src/data/models/validate_otp_request.dart';
import 'package:otp/src/domain/repositories/otp_repository.dart';
import 'package:otp/src/domain/usecases/otp_params.dart';

class OtpRepositoryImpl implements OtpRepository {
  const OtpRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final OtpRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  TaskEither<Failure, LoginResponseEntity> validateOtp(
    ValidateOtpParams params,
  ) =>
      _remoteDataSource
          .validateOtp(
            ValidateOtpRequest(
              identifier: params.identifier,
              otp: params.otp,
              purpose: params.purpose,
            ),
          )
          .map((r) => r.toEntity())
          .chainFirst((entity) => _localDataSource.saveUser(entity.user));

  @override
  TaskEither<Failure, void> resendOtp(ResendOtpParams params) =>
      _remoteDataSource.resendOtp(
        identifier: params.identifier,
        purpose: params.purpose.wireValue,
      );
}
