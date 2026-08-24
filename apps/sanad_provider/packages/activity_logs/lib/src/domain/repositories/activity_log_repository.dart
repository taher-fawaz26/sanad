import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ActivityLogRepository {
  TaskEither<Failure, Page<ActivityLogEntry>> getActivityLogs(
    ActivityLogQuery query,
  );
}
