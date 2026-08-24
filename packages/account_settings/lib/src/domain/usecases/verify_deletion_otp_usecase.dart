import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

class VerifyDeletionOtpParams extends Equatable {
  const VerifyDeletionOtpParams({required this.otp});

  final String otp;

  @override
  List<Object?> get props => [otp];
}

class VerifyDeletionOtpUseCase
    implements UseCase<AccountDeletionRequest, VerifyDeletionOtpParams> {
  const VerifyDeletionOtpUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  TaskEither<Failure, AccountDeletionRequest> call(
    VerifyDeletionOtpParams params,
  ) => _repository.verifyOtp(params.otp);
}
