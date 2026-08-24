import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ResendDeletionOtpUseCase
    implements UseCase<AccountDeletionRequest, NoParams> {
  const ResendDeletionOtpUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  TaskEither<Failure, AccountDeletionRequest> call(NoParams params) =>
      _repository.resendOtp();
}
