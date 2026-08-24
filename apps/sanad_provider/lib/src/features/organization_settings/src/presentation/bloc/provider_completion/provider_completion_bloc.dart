import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/cache/provider_completion_cache_store.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';

part 'provider_completion_event.dart';
part 'provider_completion_state.dart';

/// Owns the "Complete your organization setup" card data —
/// `GET service-provider/completion`.
///
/// Cache-first with stale-while-revalidate: fresh cached data is served
/// without a network call; stale/absent data is fetched. A
/// [ProviderCompletionRefreshed] always re-fetches (used after returning from
/// a setup flow, and on locale change). Entries are keyed by language so a
/// locale switch never shows the previous language's item labels.
class ProviderCompletionBloc
    extends Bloc<ProviderCompletionEvent, ProviderCompletionState> {
  ProviderCompletionBloc({
    required GetProviderCompletionUseCase getCompletion,
    required ProviderCompletionCacheStore cacheStore,
    required String Function() resolveLanguageCode,
  }) : _getCompletion = getCompletion,
       _cacheStore = cacheStore,
       _resolveLanguageCode = resolveLanguageCode,
       super(const ProviderCompletionState()) {
    on<ProviderCompletionLoaded>(_onLoaded);
    on<ProviderCompletionRefreshed>(_onLoaded);
  }

  final GetProviderCompletionUseCase _getCompletion;
  final ProviderCompletionCacheStore _cacheStore;
  final String Function() _resolveLanguageCode;

  Future<void> _onLoaded(
    ProviderCompletionEvent event,
    Emitter<ProviderCompletionState> emit,
  ) async {
    final key = ProviderCompletionCacheStore.keyFor(
      languageCode: _resolveLanguageCode(),
    );
    final forced = event is ProviderCompletionRefreshed;
    // A forced refresh must not serve a stale snapshot as the final state —
    // drop the entry so a fetch failure surfaces rather than masking.
    if (forced) _cacheStore.invalidate();
    final cached = forced ? null : _cacheStore.read(key);

    if (cached != null) {
      emit(
        state.copyWith(
          status: RequestStatus.success,
          completion: cached.completion,
          clearFailure: true,
        ),
      );
      if (!cached.isStale) return;
    } else {
      emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    }

    final result = await _getCompletion(const NoParams()).run();

    result.fold(
      (failure) {
        if (cached == null) {
          emit(state.copyWith(status: RequestStatus.failure, failure: failure));
        }
      },
      (completion) {
        _cacheStore.write(key, completion);
        emit(
          state.copyWith(
            status: RequestStatus.success,
            completion: completion,
            clearFailure: true,
          ),
        );
      },
    );
  }
}
