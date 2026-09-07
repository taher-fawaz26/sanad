import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/auth_response_model.dart';
import 'package:auth/src/data/models/requests/client_otp_request.dart';
import 'package:auth/src/data/models/requests/email_otp_request.dart';
import 'package:auth/src/data/models/requests/update_client_profile_request.dart';
import 'package:auth/src/data/models/requests/verify_client_otp_request.dart';
import 'package:auth/src/data/models/requests/verify_email_otp_request.dart';
import 'package:auth/src/data/models/responses/client_profile_response_dto.dart';
import 'package:auth/src/data/models/responses/client_verify_response_dto.dart';
import 'package:auth/src/data/models/responses/login_response_dto.dart';
import 'package:auth/src/data/models/responses/me_response_dto.dart';
import 'package:auth/src/data/models/responses/resend_info_response_dto.dart';
import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/client_profile_entity.dart';
import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for passwordless email-OTP authentication.
///
/// Signup and login are separate endpoint pairs on the wire (see
/// [AuthApiPaths]) — this interface mirrors that split rather than a single
/// generic "request/verify OTP" pair, so callers can't accidentally cross
/// the two flows.
abstract class AuthRemoteDataSource {
  /// Step 1 signup — `POST /auth/signup`.
  TaskEither<Failure, void> requestSignupOtp(EmailOtpRequest model);

  /// Step 2 signup — `POST /auth/signup/verify`. Always resolves to an
  /// onboarding hand-off per the live contract.
  TaskEither<Failure, AuthResponseEntity> verifySignupOtp(
    VerifyEmailOtpRequest model,
  );

  /// Step 1 sign-in — `POST /auth/login`.
  TaskEither<Failure, void> requestLoginOtp(EmailOtpRequest model);

  /// Step 2 sign-in — `POST /auth/login/verify`. Branches on
  /// `LoginResponseDto.status` (see [LoginResult]).
  TaskEither<Failure, LoginResult> verifyLoginOtp(VerifyEmailOtpRequest model);

  /// `POST /auth/resend-otp` — single endpoint, not split by intent.
  TaskEither<Failure, void> resendOtp(EmailOtpRequest model);

  /// `GET /auth/resend-info?email=` — server-driven resend cooldown.
  TaskEither<Failure, ResendInfo> getResendInfo(String email);

  /// `GET /me` — canonical identity for every persona.
  TaskEither<Failure, AuthIdentity> getCurrentUser();

  TaskEither<Failure, void> logout();

  // ── Unified client sign-in ─────────────────────────────────────────────

  /// `POST auth/client/request-otp` — dispatch (and resend) a client code.
  TaskEither<Failure, void> requestClientOtp(ClientOtpRequest model);

  /// `GET auth/client/resend-info?method=&value=` — client resend cooldown.
  TaskEither<Failure, ResendInfo> getClientResendInfo(
    ClientAuthMethod method,
    String value,
  );

  /// `POST auth/client/verify` — verify a client code; branch on `status`.
  TaskEither<Failure, ClientVerifyResult> verifyClientOtp(
    VerifyClientOtpRequest model,
  );

  /// `PATCH clients/me` — set client display name / preferred language.
  TaskEither<Failure, ClientProfile> updateClientProfile(
    UpdateClientProfileRequest model,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, void> requestSignupOtp(EmailOtpRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.signup,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, AuthResponseEntity> verifySignupOtp(
    VerifyEmailOtpRequest model,
  ) => _apiClient.request<AuthResponseEntity>(
    path: AuthApiPaths.signupVerify,
    method: RequestMethod.post,
    body: model.toMap(),
    parser: (data) => AuthResponseModel.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, void> requestLoginOtp(EmailOtpRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.login,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, LoginResult> verifyLoginOtp(
    VerifyEmailOtpRequest model,
  ) => _apiClient.request<LoginResult>(
    path: AuthApiPaths.loginVerify,
    method: RequestMethod.post,
    body: model.toMap(),
    parser: (data) => LoginResponseModel.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, void> resendOtp(EmailOtpRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.resendOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, ResendInfo> getResendInfo(String email) =>
      _apiClient.request<ResendInfo>(
        path: AuthApiPaths.resendInfo,
        method: RequestMethod.get,
        query: {'email': email},
        parser: (data) =>
            ResendInfoModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, AuthIdentity> getCurrentUser() =>
      _apiClient.request<AuthIdentity>(
        path: AuthApiPaths.me,
        method: RequestMethod.get,
        parser: (data) =>
            MeResponseModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> logout() => _apiClient.request<void>(
    path: AuthApiPaths.logout,
    method: RequestMethod.post,
    parser: (_) {},
  );

  @override
  TaskEither<Failure, void> requestClientOtp(ClientOtpRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.clientRequestOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
        // Backend contract: Auth: None. Never ride a leftover session token.
        authRequired: false,
      );

  @override
  TaskEither<Failure, ResendInfo> getClientResendInfo(
    ClientAuthMethod method,
    String value,
  ) => _apiClient.request<ResendInfo>(
    path: AuthApiPaths.clientResendInfo,
    method: RequestMethod.get,
    query: {'method': method.value, 'value': value},
    parser: (data) => ResendInfoModel.fromJson(data as Map<String, dynamic>),
    // Backend contract: Auth: None.
    authRequired: false,
  );

  @override
  TaskEither<Failure, ClientVerifyResult> verifyClientOtp(
    VerifyClientOtpRequest model,
  ) => _apiClient.request<ClientVerifyResult>(
    path: AuthApiPaths.clientVerify,
    method: RequestMethod.post,
    body: model.toMap(),
    parser: (data) =>
        ClientVerifyResponseModel.fromJson(data as Map<String, dynamic>),
    // Backend contract: Auth: None — issues a brand-new session.
    authRequired: false,
  );

  @override
  TaskEither<Failure, ClientProfile> updateClientProfile(
    UpdateClientProfileRequest model,
  ) => _apiClient.request<ClientProfile>(
    path: AuthApiPaths.clientsMe,
    method: RequestMethod.patch,
    body: model.toMap(),
    parser: (data) =>
        ClientProfileResponseModel.fromJson(data as Map<String, dynamic>),
  );
}
