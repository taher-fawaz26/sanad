import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/repositories/activity_log_repository.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

export 'package:activity_logs/src/domain/usecases/activity_log_query.dart';

class GetActivityLogsUseCase
    implements UseCase<Page<ActivityLogEntry>, ActivityLogQuery> {
  const GetActivityLogsUseCase(this._repository);

  final ActivityLogRepository _repository;

  @override
  TaskEither<Failure, Page<ActivityLogEntry>> call(ActivityLogQuery query) =>
      _repository.getActivityLogs(query);
}
