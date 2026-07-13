import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchesUseCase
    implements UseCase<PaginatedBranchesEntity, GetBranchesParams> {
  const GetBranchesUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, PaginatedBranchesEntity> call(
    GetBranchesParams params,
  ) =>
      _repository.getBranches(params);
}
