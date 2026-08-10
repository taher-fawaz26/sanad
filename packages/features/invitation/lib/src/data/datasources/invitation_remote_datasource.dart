import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/data/endpoints/invitation_api_paths.dart';
import 'package:invitation/src/data/models/requests/accept_invitation_request.dart';
import 'package:invitation/src/data/models/requests/invitation_token_request.dart';
import 'package:invitation/src/data/models/responses/invitation_preview_response_dto.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:network/network.dart';

/// Remote data source for the worker-invitation acceptance flow. None of
/// these calls carry a bearer token — the invitee isn't authenticated yet.
abstract class InvitationRemoteDataSource {
  /// `GET /workers/verify-token/{token}`.
  TaskEither<Failure, InvitationPreview> verifyToken(String token);

  /// `POST /workers/invitations/request-otp` — sends the first OTP.
  TaskEither<Failure, void> requestOtp(String token);

  /// `POST /workers/invitations/resend-otp` — resends an already-active OTP.
  TaskEither<Failure, void> resendOtp(String token);

  /// `GET /workers/invitations/resend-info/{token}` — server-driven resend
  /// cooldown.
  TaskEither<Failure, ResendInfo> getResendInfo(String token);

  /// `POST /workers/invitations/accept` — resolves to the same full-session
  /// shape as `auth/profile`.
  TaskEither<Failure, AuthSessionEntity> accept({
    required String token,
    required String otp,
  });
}

class InvitationRemoteDataSourceImpl implements InvitationRemoteDataSource {
  const InvitationRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, InvitationPreview> verifyToken(String token) =>
      _apiClient.request<InvitationPreview>(
        path: InvitationApiPaths.verifyToken(token),
        method: RequestMethod.get,
        parser: (data) =>
            InvitationPreviewModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> requestOtp(String token) =>
      _apiClient.request<void>(
        path: InvitationApiPaths.requestOtp,
        method: RequestMethod.post,
        body: InvitationTokenRequest(token: token).toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> resendOtp(String token) => _apiClient.request<void>(
    path: InvitationApiPaths.resendOtp,
    method: RequestMethod.post,
    body: InvitationTokenRequest(token: token).toMap(),
    parser: (_) {},
  );

  @override
  TaskEither<Failure, ResendInfo> getResendInfo(String token) =>
      _apiClient.request<ResendInfo>(
        path: InvitationApiPaths.resendInfo(token),
        method: RequestMethod.get,
        parser: (data) =>
            ResendInfoModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, AuthSessionEntity> accept({
    required String token,
    required String otp,
  }) => _apiClient.request<AuthSessionEntity>(
    path: InvitationApiPaths.accept,
    method: RequestMethod.post,
    body: AcceptInvitationRequest(token: token, otp: otp).toMap(),
    parser: (data) =>
        AuthSessionResponseModel.fromJson(data as Map<String, dynamic>),
  );
}
