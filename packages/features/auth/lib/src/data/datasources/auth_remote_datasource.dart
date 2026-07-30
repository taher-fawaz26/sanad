import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/email_verify_response.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for passwordless email-OTP authentication.
abstract class AuthRemoteDataSource {
  /// Requests an OTP to be delivered to `model.email`.
  TaskEither<Failure, void> requestEmailOtp(EmailOtpRequest model);

  /// Verifies the OTP and resolves to either an authenticated session or an
  /// onboarding hand-off.
  TaskEither<Failure, EmailAuthResult> verifyEmailOtp(
    VerifyEmailOtpRequest model,
  );

  TaskEither<Failure, void> logout();

  TaskEither<Failure, void> deleteAccount({required String userSub});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, void> requestEmailOtp(EmailOtpRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.emailRequestOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, EmailAuthResult> verifyEmailOtp(
    VerifyEmailOtpRequest model,
  ) =>
      _apiClient.request<EmailAuthResult>(
        path: AuthApiPaths.emailVerify,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (data) =>
            EmailVerifyResponse.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> logout() => _apiClient.request<void>(
        path: AuthApiPaths.logout,
        method: RequestMethod.post,
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> deleteAccount({required String userSub}) =>
      _apiClient.request<void>(
        path: AuthApiPaths.userDelete(userSub),
        method: RequestMethod.delete,
        parser: (_) {},
      );
}
