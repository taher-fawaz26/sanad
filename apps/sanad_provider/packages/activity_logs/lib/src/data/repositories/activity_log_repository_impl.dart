import 'package:activity_logs/src/data/datasources/activity_log_remote_data_source.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/repositories/activity_log_repository.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  const ActivityLogRepositoryImpl(this._remoteDataSource);

  final ActivityLogRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, Page<ActivityLogEntry>> getActivityLogs(
    ActivityLogQuery query,
  ) => _remoteDataSource
      .getActivityLogs(query)
      .map((page) => page.mapItems((dto) => dto.toEntity()));
}
