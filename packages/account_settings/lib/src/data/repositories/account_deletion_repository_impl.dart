import 'package:account_settings/src/data/datasources/account_deletion_remote_datasource.dart';
import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  const AccountDeletionRepositoryImpl(this._remote, this._networkGuard);

  final AccountDeletionRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, AccountDeletionEligibility> getEligibility() =>
      _networkGuard.execute(
        action: _remote.getEligibility().map((dto) => dto.toEntity()),
      );

  @override
  TaskEither<Failure, AccountDeletionRequest> startDeletion() =>
      _networkGuard.execute(
        action: _remote.startDeletion().map((dto) => dto.toEntity()),
      );

  @override
  TaskEither<Failure, AccountDeletionRequest> verifyOtp(String otp) =>
      _networkGuard.execute(
        action: _remote.verifyOtp(otp).map((dto) => dto.toEntity()),
      );

  @override
  TaskEither<Failure, AccountDeletionRequest> resendOtp() =>
      _networkGuard.execute(
        action: _remote.resendOtp().map((dto) => dto.toEntity()),
      );

  @override
  TaskEither<Failure, DeletionResendInfo> getResendInfo() =>
      _networkGuard.execute(
        action: _remote.getResendInfo().map((dto) => dto.toEntity()),
      );

  @override
  TaskEither<Failure, AccountDeletionRequest?> getStatus() =>
      _networkGuard.execute(
        action: _remote.getStatus().map((dto) => dto?.toEntity()),
      );

  @override
  TaskEither<Failure, Unit> cancelDeletion() =>
      _networkGuard.execute(action: _remote.cancelDeletion());
}
