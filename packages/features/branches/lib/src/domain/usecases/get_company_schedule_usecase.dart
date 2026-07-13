import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetCompanyScheduleUseCase
    implements UseCase<List<BranchAvailabilityEntity>, NoParams> {
  const GetCompanyScheduleUseCase(this._repository);

  final BranchRepository _repository;

  @override
  TaskEither<Failure, List<BranchAvailabilityEntity>> call(NoParams params) =>
      _repository.getCompanySchedule();
}
