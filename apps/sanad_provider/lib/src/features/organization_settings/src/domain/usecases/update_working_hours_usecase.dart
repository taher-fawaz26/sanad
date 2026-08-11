import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/working_hours_repository.dart';

class UpdateWorkingHoursUseCase
    implements
        UseCase<List<WorkingHoursDayEntity>?, List<WorkingHoursDayEntity>> {
  const UpdateWorkingHoursUseCase(this._repository);

  final WorkingHoursRepository _repository;

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> call(
    List<WorkingHoursDayEntity> params,
  ) => _repository.updateWorkingHours(params);
}
