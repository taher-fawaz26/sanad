import 'package:auth/src/data/datasources/auth_local_datasource.dart';
import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/validate_email_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._googleDataSource,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final GoogleAuthDataSource _googleDataSource;

  @override
  TaskEither<Failure, AuthResponseEntity> signInWithGoogle() =>
      _googleDataSource.signInWithGoogle().chainFirst(
        (response) => switch (response) {
          AuthSessionEntity(:final user) => _localDataSource.saveUser(user),
          OnboardingAuthEntity() => TaskEither.right(null),
        },
      );

  @override
  TaskEither<Failure, void> requestEmailOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.requestEmailOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, AuthResponseEntity> verifyEmailOtp(
    VerifyEmailOtpParams params,
  ) => _remoteDataSource
      .verifyEmailOtp(
        VerifyEmailOtpRequest(email: params.email, otp: params.otp),
      )
      // Persist the user locally when the account is fully authenticated so
      // a session can be restored on next launch.
      .chainFirst(
        (response) => switch (response) {
          AuthSessionEntity(:final user) => _localDataSource.saveUser(user),
          OnboardingAuthEntity() => TaskEither.right(null),
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

  @override
  TaskEither<Failure, bool> validateEmail(ValidateEmailParams params) =>
      _remoteDataSource.validateEmail(
        ValidateEmailRequest(email: params.email),
      );
}
