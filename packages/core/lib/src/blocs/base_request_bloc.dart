import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/src/blocs/base_request_state.dart';
import 'package:core/src/bus/locale_change_bus.dart';
import 'package:core/src/domain/usecases/usecase.dart';

// ─── Events ──────────────────────────────────────────────────────────

abstract class BaseRequestEvent<P> {
  const BaseRequestEvent(this.params);
  final P params;
}

class FetchEvent<P> extends BaseRequestEvent<P> {
  const FetchEvent(super.params);
}

class RefreshEvent<P> extends BaseRequestEvent<P> {
  const RefreshEvent(super.params);
}

class RetryEvent<P> extends BaseRequestEvent<P> {
  const RetryEvent(super.params);
}

// ─── Bloc ────────────────────────────────────────────────────────────

/// Generic BLoC that manages a single async [UseCase] call.
///
/// Subscribes to [LocaleChangeBus] (optional) to auto-refresh data
/// when the app language changes. The concrete bus is injected at the
/// call-site; this package knows only the abstract contract.
class BaseRequestBloc<T, P>
    extends Bloc<BaseRequestEvent<P>, BaseRequestState<T>> {
  BaseRequestBloc({
    required this.useCase,
    required P initialParams,
    bool autoFetch = true,
    LocaleChangeBus? localeChangeBus,
  })  : _lastParams = initialParams,
        super(const BaseRequestState.initial()) {
    on<FetchEvent<P>>(_onFetch);
    on<RefreshEvent<P>>(_onRefresh);
    on<RetryEvent<P>>(_onRetry);

    _localeSubscription = localeChangeBus?.changes.listen((_) {
      if (!isClosed && state.status != RequestStatus.initial) {
        add(RefreshEvent<P>(_lastParams));
      }
    });

    if (autoFetch) add(FetchEvent<P>(initialParams));
  }

  final UseCase<T, P> useCase;
  P _lastParams;
  StreamSubscription<void>? _localeSubscription;

  P get lastParams => _lastParams;
  void retry() => add(RetryEvent<P>(_lastParams));

  Future<void> _onFetch(
    FetchEvent<P> event,
    Emitter<BaseRequestState<T>> emit,
  ) async {
    _lastParams = event.params;
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _execute(event.params, emit);
  }

  Future<void> _onRefresh(
    RefreshEvent<P> event,
    Emitter<BaseRequestState<T>> emit,
  ) async {
    _lastParams = event.params;
    emit(BaseRequestState<T>.loading());
    await _execute(event.params, emit);
  }

  Future<void> _onRetry(
    RetryEvent<P> event,
    Emitter<BaseRequestState<T>> emit,
  ) async {
    _lastParams = event.params;
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _execute(event.params, emit);
  }

  Future<void> _execute(P params, Emitter<BaseRequestState<T>> emit) async {
    final result = await useCase.call(params).run();
    result.fold(
      (failure) => emit(BaseRequestState<T>.failure(failure)),
      (data) => emit(BaseRequestState<T>.success(data)),
    );
  }

  @override
  Future<void> close() async {
    await _localeSubscription?.cancel();
    await super.close();
  }
}
