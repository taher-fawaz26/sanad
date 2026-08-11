import 'package:branches/src/domain/entities/paginated_managers_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchManagersUseCase
    implements UseCase<PaginatedManagersEntity, GetBranchManagersParams> {
  const GetBranchManagersUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, PaginatedManagersEntity> call(
    GetBranchManagersParams params,
  ) => _repository.getBranchManagers(params);
}
