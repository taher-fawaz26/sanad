import 'package:activity_logs/src/cache/activity_log_cache_store.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/usecases/get_activity_logs_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'recent_activity_state.dart';

/// Global "latest N activity" slice (Home dashboard "Recent Activity"
/// preview) — no `actorId` filter, no pagination, no "see all" affordance.
/// For a single actor's feed, use `WorkerActivityCubit` instead.
class RecentActivityCubit extends Cubit<RecentActivityState> {
  RecentActivityCubit({
    required GetActivityLogsUseCase getActivityLogsUseCase,
    required ActivityLogCacheStore cacheStore,
    this.limit = 5,
  }) : _getActivityLogsUseCase = getActivityLogsUseCase,
       _cacheStore = cacheStore,
       super(const RecentActivityState());

  final GetActivityLogsUseCase _getActivityLogsUseCase;
  final ActivityLogCacheStore _cacheStore;
  final int limit;

  bool _loading = false;

  Future<void> load({
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    if (_loading) return;

    final cacheKey = ActivityLogCacheStore.keyFor(
      actorId: null,
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
      ActivityLogQuery(limit: limit),
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
