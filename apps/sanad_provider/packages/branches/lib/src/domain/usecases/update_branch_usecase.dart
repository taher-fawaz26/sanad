import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class UpdateBranchUseCase implements UseCase<BranchEntity, UpdateBranchParams> {
  const UpdateBranchUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, BranchEntity> call(UpdateBranchParams params) =>
      _repository.updateBranch(params);
}
