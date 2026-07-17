import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class UpdateBranchStatusUseCase
    implements UseCase<BranchEntity, UpdateBranchStatusParams> {
  const UpdateBranchStatusUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, BranchEntity> call(UpdateBranchStatusParams params) =>
      _repository.updateBranchStatus(params);
}
