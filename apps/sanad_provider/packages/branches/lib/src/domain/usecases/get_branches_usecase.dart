import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchesUseCase implements UseCase<Page<BranchEntity>, BranchesQuery> {
  const GetBranchesUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, Page<BranchEntity>> call(BranchesQuery query) =>
      _repository.getBranches(query);
}
