import 'package:auth/src/data/datasources/auth_local_datasource.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/domain/entities/email_auth_result.dart';
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
  TaskEither<Failure, void> requestEmailOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.requestEmailOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, EmailAuthResult> verifyEmailOtp(
    VerifyEmailOtpParams params,
  ) =>
      _remoteDataSource
          .verifyEmailOtp(
            VerifyEmailOtpRequest(email: params.email, otp: params.otp),
          )
          // Persist the user locally when the account is fully authenticated so
          // a session can be restored on next launch.
          .chainFirst(
            (result) => switch (result) {
              AuthenticatedResult(:final user) =>
                _localDataSource.saveUser(user),
              OnboardingResult() => TaskEither.right(null),
            },
          );

  @override
  TaskEither<Failure, void> logout() =>
      _remoteDataSource.logout().flatMap((_) => _localDataSource.clearUser());

  @override
  TaskEither<Failure, UserEntity?> checkSignInStatus() =>
      _localDataSource.checkSignInStatus();

  @override
  TaskEither<Failure, void> deleteAccount(DeleteAccountParams params) =>
      _remoteDataSource
          .deleteAccount(userSub: params.userSub)
          .flatMap((_) => _localDataSource.clearUser());
}
