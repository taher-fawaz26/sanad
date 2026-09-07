import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class BranchRepository {
  TaskEither<Failure, Page<BranchEntity>> getBranches(BranchesQuery query);

  TaskEither<Failure, BranchEntity> getBranch(GetBranchParams params);

  TaskEither<Failure, BranchEntity> createBranch(CreateBranchParams params);

  TaskEither<Failure, BranchEntity> updateBranch(UpdateBranchParams params);

  TaskEither<Failure, BranchEntity> updateBranchStatus(
    UpdateBranchStatusParams params,
  );

  TaskEither<Failure, void> deleteBranch(DeleteBranchParams params);

  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule();

  TaskEither<Failure, Page<BranchManagerEntity>> getBranchManagers(
    BranchManagersQuery query,
  );
}
