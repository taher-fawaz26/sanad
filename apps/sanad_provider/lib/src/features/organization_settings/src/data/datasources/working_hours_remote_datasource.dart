import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/working_hours_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/working_hours_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';

/// Remote data source for `service-provider/working-hours`.
abstract interface class WorkingHoursRemoteDataSource {
  TaskEither<Failure, WorkingHoursResponse> getWorkingHours();

  /// Send an empty [availability] list to clear all working hours.
  TaskEither<Failure, WorkingHoursResponse> updateWorkingHours(
    List<WorkingHoursDayEntity> availability,
  );
}

class WorkingHoursRemoteDataSourceImpl implements WorkingHoursRemoteDataSource {
  const WorkingHoursRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, WorkingHoursResponse> getWorkingHours() =>
      _apiClient.request<WorkingHoursResponse>(
        path: WorkingHoursApiPaths.workingHours,
        method: RequestMethod.get,
        parser: (data) =>
            WorkingHoursResponse.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, WorkingHoursResponse> updateWorkingHours(
    List<WorkingHoursDayEntity> availability,
  ) => _apiClient.request<WorkingHoursResponse>(
    path: WorkingHoursApiPaths.workingHours,
    method: RequestMethod.put,
    body: {
      'availability': availability
          .map(
            (day) => {
              'day': day.day,
              'slots': day.slots
                  .map((slot) => {'from': slot.from, 'to': slot.to})
                  .toList(),
            },
          )
          .toList(),
    },
    parser: (data) =>
        WorkingHoursResponse.fromJson(data as Map<String, dynamic>),
  );
}
