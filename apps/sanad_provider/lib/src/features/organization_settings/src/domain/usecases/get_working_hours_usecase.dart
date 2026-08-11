import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/working_hours_repository.dart';

class GetWorkingHoursUseCase
    implements UseCase<List<WorkingHoursDayEntity>?, NoParams> {
  const GetWorkingHoursUseCase(this._repository);

  final WorkingHoursRepository _repository;

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> call(NoParams params) =>
      _repository.getWorkingHours();
}
