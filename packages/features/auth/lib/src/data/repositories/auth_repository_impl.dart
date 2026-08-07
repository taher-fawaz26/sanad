import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/validate_email_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Auth repository — pure remote pipeline. Local persistence of the
/// authenticated session is not done here anymore: the presentation layer
/// hands the parsed [AuthSessionEntity] to `SessionManager.save` after a
/// successful verify/google sign-in. See `AuthOtpVerifier` and
/// `AuthBloc._signInWithGoogle`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._googleDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final GoogleAuthDataSource _googleDataSource;

  @override
  TaskEither<Failure, AuthResponseEntity> signInWithGoogle() =>
      _googleDataSource.signInWithGoogle();

  @override
  TaskEither<Failure, void> requestEmailOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.requestEmailOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, AuthResponseEntity> verifyEmailOtp(
    VerifyEmailOtpParams params,
  ) => _remoteDataSource.verifyEmailOtp(
    VerifyEmailOtpRequest(email: params.email, otp: params.otp),
  );

  @override
  TaskEither<Failure, void> logout() => _remoteDataSource.logout();

  @override
  TaskEither<Failure, void> deleteAccount(DeleteAccountParams params) =>
      _remoteDataSource.deleteAccount(userSub: params.userSub);

  @override
  TaskEither<Failure, bool> validateEmail(ValidateEmailParams params) =>
      _remoteDataSource.validateEmail(
        ValidateEmailRequest(email: params.email),
      );
}
