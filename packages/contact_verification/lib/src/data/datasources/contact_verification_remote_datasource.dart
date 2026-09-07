import 'package:contact_verification/src/data/endpoints/contact_verification_api_paths.dart';
import 'package:contact_verification/src/data/models/verification_dispatch_response.dart';
import 'package:contact_verification/src/data/models/verification_resend_info_response.dart';
import 'package:contact_verification/src/data/models/verification_result_response.dart';
import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

abstract interface class ContactVerificationRemoteDataSource {
  TaskEither<Failure, VerificationDispatchResponse> requestCode({
    required VerificationPurpose purpose,
    required String target,
  });

  TaskEither<Failure, VerificationDispatchResponse> resendCode({
    required VerificationPurpose purpose,
  });

  TaskEither<Failure, VerificationResendInfoResponse> getResendInfo({
    required VerificationPurpose purpose,
  });

  TaskEither<Failure, VerificationResultResponse> verifyCode({
    required VerificationPurpose purpose,
    required String code,
  });
}

class ContactVerificationRemoteDataSourceImpl
    implements ContactVerificationRemoteDataSource {
  ContactVerificationRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, VerificationDispatchResponse> requestCode({
    required VerificationPurpose purpose,
    required String target,
  }) => _apiClient.request<VerificationDispatchResponse>(
    path: ContactVerificationApiPaths.request,
    method: RequestMethod.post,
    body: {'purpose': purpose.toApi(), 'target': target},
    parser: (data) => VerificationDispatchResponse.fromJson(
      data as Map<String, dynamic>,
    ),
  );

  @override
  TaskEither<Failure, VerificationDispatchResponse> resendCode({
    required VerificationPurpose purpose,
  }) => _apiClient.request<VerificationDispatchResponse>(
    path: ContactVerificationApiPaths.resend,
    method: RequestMethod.post,
    body: {'purpose': purpose.toApi()},
    parser: (data) => VerificationDispatchResponse.fromJson(
      data as Map<String, dynamic>,
    ),
  );

  @override
  TaskEither<Failure, VerificationResendInfoResponse> getResendInfo({
    required VerificationPurpose purpose,
  }) => _apiClient.request<VerificationResendInfoResponse>(
    path: ContactVerificationApiPaths.resendInfo,
    method: RequestMethod.get,
    query: {'purpose': purpose.toApi()},
    parser: (data) => VerificationResendInfoResponse.fromJson(
      data as Map<String, dynamic>,
    ),
  );

  @override
  TaskEither<Failure, VerificationResultResponse> verifyCode({
    required VerificationPurpose purpose,
    required String code,
  }) => _apiClient.request<VerificationResultResponse>(
    path: ContactVerificationApiPaths.verify,
    method: RequestMethod.post,
    body: {'purpose': purpose.toApi(), 'code': code},
    parser: (data) => VerificationResultResponse.fromJson(
      data as Map<String, dynamic>,
      requestedPurpose: purpose,
    ),
  );
}
