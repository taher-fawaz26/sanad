import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/home/src/data/cache/provider_statistics_cache_store.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/domain/usecases/get_provider_statistics_usecase.dart';

part 'provider_statistics_event.dart';
part 'provider_statistics_state.dart';

/// Owns the dashboard statistic cards shown on the provider home page —
/// `GET service-provider/statistics`.
///
/// Cache-first with stale-while-revalidate: fresh cached data is served
/// without a network call; stale/absent data is fetched. Cached entries are
/// keyed by language so a locale switch never shows the previous language's
/// labels. See [ProviderStatisticsCacheStore].
class ProviderStatisticsBloc
    extends Bloc<ProviderStatisticsEvent, ProviderStatisticsState> {
  ProviderStatisticsBloc({
    required GetProviderStatisticsUseCase getStatistics,
    required ProviderStatisticsCacheStore cacheStore,
    required String Function() resolveLanguageCode,
  }) : _getStatistics = getStatistics,
       _cacheStore = cacheStore,
       _resolveLanguageCode = resolveLanguageCode,
       super(const ProviderStatisticsState()) {
    on<ProviderStatisticsLoaded>(_onLoaded);
    on<ProviderStatisticsRefreshed>(_onLoaded);
  }

  final GetProviderStatisticsUseCase _getStatistics;
  final ProviderStatisticsCacheStore _cacheStore;

  /// Resolves the active language at handle time (same source the network
  /// layer uses: `TranslateBloc.state.languageCode`), so a re-fetch after a
  /// locale change reads the new language for both the cache key and headers.
  final String Function() _resolveLanguageCode;

  Future<void> _onLoaded(
    ProviderStatisticsEvent event,
    Emitter<ProviderStatisticsState> emit,
  ) async {
    final key = ProviderStatisticsCacheStore.keyFor(
      languageCode: _resolveLanguageCode(),
    );
    final forced = event is ProviderStatisticsRefreshed;
    final cached = _cacheStore.read(key);

    if (cached != null) {
      // Serve cached immediately — no spinner on revisit.
      emit(
        state.copyWith(
          status: RequestStatus.success,
          statistics: cached.items,
          clearFailure: true,
        ),
      );
      // Fresh and not explicitly forced → done, no network call.
      if (!cached.isStale && !forced) return;
    } else {
      emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    }

    final result = await _getStatistics(const NoParams()).run();

    result.fold(
      (failure) {
        // Keep already-shown cached data on a background-refresh failure;
        // only surface the error when there is nothing to show.
        if (cached == null) {
          emit(state.copyWith(status: RequestStatus.failure, failure: failure));
        }
      },
      (statistics) {
        _cacheStore.write(key, statistics);
        emit(
          state.copyWith(
            status: RequestStatus.success,
            statistics: statistics,
            clearFailure: true,
          ),
        );
      },
    );
  }
}
