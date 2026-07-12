import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchManagersUseCase
    implements UseCase<List<BranchManagerEntity>, NoParams> {
  const GetBranchManagersUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, List<BranchManagerEntity>> call(NoParams params) =>
      _repository.getBranchManagers();
}
