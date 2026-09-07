import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchManagersUseCase
    implements UseCase<Page<BranchManagerEntity>, BranchManagersQuery> {
  const GetBranchManagersUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, Page<BranchManagerEntity>> call(
    BranchManagersQuery query,
  ) => _repository.getBranchManagers(query);
}
