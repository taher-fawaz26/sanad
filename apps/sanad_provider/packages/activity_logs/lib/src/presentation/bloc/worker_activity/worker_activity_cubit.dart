import 'package:activity_logs/src/cache/activity_log_cache_store.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/usecases/get_activity_logs_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'worker_activity_state.dart';

/// Fixed recent-activity slice for one worker (Worker Details "Recent
/// Activity" card). Deliberately not paginated — the design shows a fixed
/// slice with no "see all" affordance; a full paginated/filterable feed
/// would reuse [ActivityLogQuery] from a separate, larger screen instead.
class WorkerActivityCubit extends Cubit<WorkerActivityState> {
  WorkerActivityCubit({
    required GetActivityLogsUseCase getActivityLogsUseCase,
    required ActivityLogCacheStore cacheStore,
    this.limit = 10,
  }) : _getActivityLogsUseCase = getActivityLogsUseCase,
       _cacheStore = cacheStore,
       super(const WorkerActivityState());

  final GetActivityLogsUseCase _getActivityLogsUseCase;
  final ActivityLogCacheStore _cacheStore;
  final int limit;

  bool _loading = false;

  Future<void> load({
    required String actorId,
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    if (_loading) return;

    final cacheKey = ActivityLogCacheStore.keyFor(
      actorId: actorId,
      languageCode: languageCode,
    );
    if (!forceRefresh) {
      final cached = _cacheStore.read(cacheKey);
      if (cached != null) {
        emit(state.copyWith(status: RequestStatus.success, items: cached));
        return;
      }
    }

    _loading = true;
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getActivityLogsUseCase(
      ActivityLogQuery(actorId: actorId, limit: limit),
    ).run();

    result.match(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (page) {
        _cacheStore.write(cacheKey, page.items);
        emit(state.copyWith(status: RequestStatus.success, items: page.items));
      },
    );
    _loading = false;
  }
}
