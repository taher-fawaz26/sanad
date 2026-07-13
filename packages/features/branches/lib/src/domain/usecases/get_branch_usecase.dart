import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetBranchUseCase implements UseCase<BranchEntity, GetBranchParams> {
  const GetBranchUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, BranchEntity> call(GetBranchParams params) =>
      _repository.getBranch(params);
}
