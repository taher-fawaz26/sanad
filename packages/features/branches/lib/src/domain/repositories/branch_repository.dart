import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/entities/paginated_managers_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class BranchRepository {
  TaskEither<Failure, PaginatedBranchesEntity> getBranches(
    GetBranchesParams params,
  );

  TaskEither<Failure, BranchEntity> getBranch(GetBranchParams params);

  TaskEither<Failure, BranchEntity> createBranch(CreateBranchParams params);

  TaskEither<Failure, BranchEntity> updateBranch(UpdateBranchParams params);

  TaskEither<Failure, BranchEntity> updateBranchStatus(
    UpdateBranchStatusParams params,
  );

  TaskEither<Failure, void> deleteBranch(DeleteBranchParams params);

  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule();

  TaskEither<Failure, PaginatedManagersEntity> getBranchManagers(
    GetBranchManagersParams params,
  );
}
