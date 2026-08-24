/// Activity Logs — domain, data, presentation, and DI for the
/// `GET /activity-logs` backend feature.
///
/// UI consumers: `WorkerRecentActivitySection` (actor-filtered, Worker
/// Details) and `HomeRecentActivitySection` (global latest-5, Home
/// dashboard). The domain/data layers support the full backend filter
/// surface (actor, subject, action, date range, pagination) for future
/// reuse — a full Activity screen, subject/actor history, etc.
library;

// DI
export 'src/di/activity_logs_di.dart';
// Domain — entities
export 'src/domain/entities/activity_action.dart';
export 'src/domain/entities/activity_actor.dart';
export 'src/domain/entities/activity_log_entry.dart';
export 'src/domain/entities/activity_metadata.dart';
export 'src/domain/entities/activity_subject.dart';
// Domain — repository
export 'src/domain/repositories/activity_log_repository.dart';
// Domain — use case (also exports ActivityLogQuery)
export 'src/domain/usecases/get_activity_logs_usecase.dart';
// Presentation — bloc
export 'src/presentation/bloc/recent_activity/recent_activity_cubit.dart';
export 'src/presentation/bloc/worker_activity/worker_activity_cubit.dart';
// Presentation — widgets
export 'src/presentation/widgets/home_recent_activity_section.dart';
export 'src/presentation/widgets/worker_recent_activity_section.dart';
