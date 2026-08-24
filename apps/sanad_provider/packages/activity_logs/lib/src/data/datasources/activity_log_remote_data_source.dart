import 'package:activity_logs/src/data/endpoints/activity_log_api_paths.dart';
import 'package:activity_logs/src/data/models/activity_log_dto.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

abstract interface class ActivityLogRemoteDataSource {
  TaskEither<Failure, Page<ActivityLogDto>> getActivityLogs(
    ActivityLogQuery query,
  );
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  const ActivityLogRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, Page<ActivityLogDto>> getActivityLogs(
    ActivityLogQuery query,
  ) => _apiClient.request<Page<ActivityLogDto>>(
    path: ActivityLogApiPaths.activityLogs,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) => parsePage(data, ActivityLogDto.fromJson),
  );
}
