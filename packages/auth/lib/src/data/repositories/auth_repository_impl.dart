import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Auth repository — pure remote pipeline. Local persistence of the
/// authenticated session is not done here anymore: the presentation layer
/// hands the parsed session/identity to `SessionManager` after a successful
/// verify/google sign-in — see `AuthBloc` and `EmailOtpPage`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._googleDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final GoogleAuthDataSource _googleDataSource;

  @override
  TaskEither<Failure, void> requestSignupOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.requestSignupOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, AuthResponseEntity> verifySignupOtp(
    VerifyEmailOtpParams params,
  ) => _remoteDataSource.verifySignupOtp(
    VerifyEmailOtpRequest(email: params.email, otp: params.otp),
  );

  @override
  TaskEither<Failure, void> requestLoginOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.requestLoginOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, LoginResult> verifyLoginOtp(
    VerifyEmailOtpParams params,
  ) => _remoteDataSource.verifyLoginOtp(
    VerifyEmailOtpRequest(email: params.email, otp: params.otp),
  );

  @override
  TaskEither<Failure, void> resendOtp(RequestEmailOtpParams params) =>
      _remoteDataSource.resendOtp(EmailOtpRequest(email: params.email));

  @override
  TaskEither<Failure, ResendInfo> getResendInfo(
    RequestEmailOtpParams params,
  ) => _remoteDataSource.getResendInfo(params.email);

  @override
  TaskEither<Failure, AuthResponseEntity> socialSignup() =>
      _googleDataSource.socialSignup();

  @override
  TaskEither<Failure, LoginResult> socialLogin() =>
      _googleDataSource.socialLogin();

  @override
  TaskEither<Failure, AuthIdentity> getCurrentUser() =>
      _remoteDataSource.getCurrentUser();

  @override
  TaskEither<Failure, void> logout() => _remoteDataSource.logout();
}
