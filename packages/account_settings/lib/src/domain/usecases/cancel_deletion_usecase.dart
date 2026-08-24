import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class CancelDeletionUseCase implements UseCase<Unit, NoParams> {
  const CancelDeletionUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  TaskEither<Failure, Unit> call(NoParams params) =>
      _repository.cancelDeletion();
}
