import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class DeleteBranchUseCase implements UseCase<void, DeleteBranchParams> {
  const DeleteBranchUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, void> call(DeleteBranchParams params) =>
      _repository.deleteBranch(params);
}
