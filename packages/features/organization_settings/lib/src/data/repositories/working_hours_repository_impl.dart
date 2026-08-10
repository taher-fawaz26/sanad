import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/working_hours_remote_datasource.dart';
import 'package:organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:organization_settings/src/domain/repositories/working_hours_repository.dart';

class WorkingHoursRepositoryImpl implements WorkingHoursRepository {
  const WorkingHoursRepositoryImpl(this._remote, this._networkGuard);

  final WorkingHoursRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> getWorkingHours() =>
      _networkGuard.execute(
        action: _remote.getWorkingHours().map(
          (response) => response.toEntity(),
        ),
      );

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> updateWorkingHours(
    List<WorkingHoursDayEntity> availability,
  ) => _networkGuard.execute(
    action: _remote
        .updateWorkingHours(availability)
        .map((response) => response.toEntity()),
  );
}
