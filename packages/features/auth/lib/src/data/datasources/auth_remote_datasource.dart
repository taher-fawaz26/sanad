import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/auth_response_model.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/validate_email_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/data/models/responses/validate_email_response.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for passwordless email-OTP authentication.
abstract class AuthRemoteDataSource {
  /// Requests an OTP to be delivered to `model.email`.
  TaskEither<Failure, void> requestEmailOtp(EmailOtpRequest model);

  /// Verifies the OTP and resolves to either an authenticated session or an
  /// onboarding hand-off.
  TaskEither<Failure, AuthResponseEntity> verifyEmailOtp(
    VerifyEmailOtpRequest model,
  );

  TaskEither<Failure, void> logout();

  TaskEither<Failure, void> deleteAccount({required String userSub});
  TaskEither<Failure, bool> validateEmail(ValidateEmailRequest model);
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
  TaskEither<Failure, AuthResponseEntity> verifyEmailOtp(
    VerifyEmailOtpRequest model,
  ) => _apiClient.request<AuthResponseEntity>(
    path: AuthApiPaths.emailVerify,
    method: RequestMethod.post,
    body: model.toMap(),
    parser: (data) => AuthResponseModel.fromJson(data as Map<String, dynamic>),
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

  @override
  TaskEither<Failure, bool> validateEmail(ValidateEmailRequest model) =>
      _apiClient.request<bool>(
        path: AuthApiPaths.validateEmail,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (data) => ValidateEmailResponseModel.fromJson(
          data as Map<String, dynamic>,
        ).emailAvailable,
      );
}
