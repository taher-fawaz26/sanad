import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetDeletionEligibilityUseCase
    implements UseCase<AccountDeletionEligibility, NoParams> {
  const GetDeletionEligibilityUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  TaskEither<Failure, AccountDeletionEligibility> call(NoParams params) =>
      _repository.getEligibility();
}
