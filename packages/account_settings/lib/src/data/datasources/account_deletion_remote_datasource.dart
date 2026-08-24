import 'package:account_settings/src/data/endpoints/account_deletion_api_paths.dart';
import 'package:account_settings/src/data/models/account_deletion_eligibility_dto.dart';
import 'package:account_settings/src/data/models/account_deletion_resend_info_dto.dart';
import 'package:account_settings/src/data/models/account_deletion_response_dto.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source for the self-service account deletion & recovery flow.
abstract interface class AccountDeletionRemoteDataSource {
  TaskEither<Failure, AccountDeletionEligibilityDto> getEligibility();

  TaskEither<Failure, AccountDeletionResponseDto> startDeletion();

  TaskEither<Failure, AccountDeletionResponseDto> verifyOtp(String otp);

  TaskEither<Failure, AccountDeletionResponseDto> resendOtp();

  TaskEither<Failure, AccountDeletionResendInfoDto> getResendInfo();

  /// `null` on 404 — no active request, a quiet state rather than a
  /// [Failure].
  TaskEither<Failure, AccountDeletionResponseDto?> getStatus();

  /// 404 (nothing to cancel) resolves as a no-op success.
  TaskEither<Failure, Unit> cancelDeletion();
}

class AccountDeletionRemoteDataSourceImpl
    implements AccountDeletionRemoteDataSource {
  const AccountDeletionRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, AccountDeletionEligibilityDto> getEligibility() =>
      _apiClient.request<AccountDeletionEligibilityDto>(
        path: AccountDeletionApiPaths.eligibility,
        method: RequestMethod.get,
        parser: (data) => AccountDeletionEligibilityDto.fromJson(
          data as Map<String, dynamic>,
        ),
      );

  @override
  TaskEither<Failure, AccountDeletionResponseDto> startDeletion() =>
      _apiClient.request<AccountDeletionResponseDto>(
        path: AccountDeletionApiPaths.deletion,
        method: RequestMethod.post,
        parser: (data) =>
            AccountDeletionResponseDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, AccountDeletionResponseDto> verifyOtp(String otp) =>
      _apiClient.request<AccountDeletionResponseDto>(
        path: AccountDeletionApiPaths.verify,
        method: RequestMethod.post,
        body: {'otp': otp},
        parser: (data) =>
            AccountDeletionResponseDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, AccountDeletionResponseDto> resendOtp() =>
      _apiClient.request<AccountDeletionResponseDto>(
        path: AccountDeletionApiPaths.resendOtp,
        method: RequestMethod.post,
        parser: (data) =>
            AccountDeletionResponseDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, AccountDeletionResendInfoDto> getResendInfo() =>
      _apiClient.request<AccountDeletionResendInfoDto>(
        path: AccountDeletionApiPaths.resendInfo,
        method: RequestMethod.get,
        parser: (data) => AccountDeletionResendInfoDto.fromJson(
          data as Map<String, dynamic>,
        ),
      );

  @override
  TaskEither<Failure, AccountDeletionResponseDto?> getStatus() =>
      TaskEither(() async {
        final result = await _apiClient
            .request<AccountDeletionResponseDto>(
              path: AccountDeletionApiPaths.deletion,
              method: RequestMethod.get,
              parser: (data) => AccountDeletionResponseDto.fromJson(
                data as Map<String, dynamic>,
              ),
            )
            .run();
        return result.match(
          (failure) =>
              failure.code == '404' ? const Right(null) : Left(failure),
          Right.new,
        );
      });

  @override
  TaskEither<Failure, Unit> cancelDeletion() => TaskEither(() async {
    final result = await _apiClient
        .request<Unit>(
          path: AccountDeletionApiPaths.deletion,
          method: RequestMethod.delete,
          parser: (_) => unit,
        )
        .run();
    return result.match(
      (failure) => failure.code == '404' ? const Right(unit) : Left(failure),
      Right.new,
    );
  });
}
