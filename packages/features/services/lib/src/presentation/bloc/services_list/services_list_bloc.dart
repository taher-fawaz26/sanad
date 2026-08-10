import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/usecases/get_services_list_usecase.dart';

part 'services_list_event.dart';
part 'services_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Owns the provider's own services list on the dashboard: fetch, refresh,
/// load-more, and search.
///
/// Does not own single-service mutations (delete / status toggle) — those
/// live in [ServiceActionBloc]; success is folded back in here via
/// [ServiceReplacedInListEvent] / [ServiceRemovedFromListEvent].
class ServicesListBloc extends Bloc<ServicesListEvent, ServicesListState> {
  ServicesListBloc({required GetServicesListUseCase getServicesListUseCase})
    : _getServicesListUseCase = getServicesListUseCase,
      super(const ServicesListState()) {
    on<ServicesListFetchEvent>(_onFetch);
    on<ServicesListRefreshEvent>(_onRefresh);
    on<ServicesListLoadMoreEvent>(_onLoadMore);
    on<ServicesListSearchChangedEvent>(_onSearchChanged);
    on<ServiceReplacedInListEvent>(_onReplaced);
    on<ServiceRemovedFromListEvent>(_onRemoved);
  }

  final GetServicesListUseCase _getServicesListUseCase;
  Timer? _searchTimer;

  String? get _search =>
      state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim();

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onFetch(
    ServicesListFetchEvent event,
    Emitter<ServicesListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    ServicesListRefreshEvent event,
    Emitter<ServicesListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onLoadMore(
    ServicesListLoadMoreEvent event,
    Emitter<ServicesListState> emit,
  ) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(emit, page: state.page + 1, append: true);
  }

  void _onSearchChanged(
    ServicesListSearchChangedEvent event,
    Emitter<ServicesListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (isClosed) return;
      add(const ServicesListFetchEvent());
    });
  }

  void _onReplaced(
    ServiceReplacedInListEvent event,
    Emitter<ServicesListState> emit,
  ) {
    final updated = state.services
        .map((s) => s.id == event.service.id ? event.service : s)
        .toList();
    emit(state.copyWith(services: updated));
  }

  void _onRemoved(
    ServiceRemovedFromListEvent event,
    Emitter<ServicesListState> emit,
  ) {
    final updated = state.services
        .where((s) => s.id != event.serviceId)
        .toList();
    emit(state.copyWith(services: updated));
  }

  Future<void> _fetch(
    Emitter<ServicesListState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getServicesListUseCase(
      GetServicesListParams(page: page, search: _search),
    ).run();

    result.fold(
      (failure) => emit(
        append
            ? state.copyWith(loadingMore: false)
            : state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (paged) => emit(
        state.copyWith(
          status: RequestStatus.success,
          services: append ? [...state.services, ...paged.items] : paged.items,
          page: paged.meta.currentPage,
          totalPages: paged.meta.totalPages,
          loadingMore: false,
        ),
      ),
    );
  }
}
