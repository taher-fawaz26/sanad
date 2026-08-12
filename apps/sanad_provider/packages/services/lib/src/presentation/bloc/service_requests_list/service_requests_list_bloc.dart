import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/domain/usecases/get_my_service_requests_usecase.dart';

part 'service_requests_list_event.dart';
part 'service_requests_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Owns the "Service request" tab: the provider's own submitted requests
/// (`GET /service-requests`), including server-side search and status
/// filter (underreview/approved/rejected/all).
class ServiceRequestsListBloc
    extends Bloc<ServiceRequestsListEvent, ServiceRequestsListState> {
  ServiceRequestsListBloc({
    required GetMyServiceRequestsUseCase getMyServiceRequestsUseCase,
  }) : _getMyServiceRequestsUseCase = getMyServiceRequestsUseCase,
       super(const ServiceRequestsListState()) {
    on<ServiceRequestsListFetchEvent>(_onFetch);
    on<ServiceRequestsListRefreshEvent>(_onRefresh);
    on<ServiceRequestsListLoadMoreEvent>(_onLoadMore);
    on<ServiceRequestsListSearchChangedEvent>(_onSearchChanged);
    on<ServiceRequestsListStatusChangedEvent>(_onStatusChanged);
  }

  final GetMyServiceRequestsUseCase _getMyServiceRequestsUseCase;
  Timer? _searchTimer;

  String? get _search =>
      state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim();

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onFetch(
    ServiceRequestsListFetchEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    ServiceRequestsListRefreshEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onLoadMore(
    ServiceRequestsListLoadMoreEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(emit, page: state.page + 1, append: true);
  }

  void _onSearchChanged(
    ServiceRequestsListSearchChangedEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (isClosed) return;
      add(const ServiceRequestsListFetchEvent());
    });
  }

  Future<void> _onStatusChanged(
    ServiceRequestsListStatusChangedEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    emit(
      state.copyWith(
        statusFilter: event.status,
        status: RequestStatus.loading,
        clearFailure: true,
      ),
    );
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _fetch(
    Emitter<ServiceRequestsListState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getMyServiceRequestsUseCase(
      GetMyServiceRequestsParams(
        page: page,
        search: _search,
        status: state.statusFilter == ServiceRequestStatus.all
            ? null
            : state.statusFilter,
      ),
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
          requests: append ? [...state.requests, ...paged.items] : paged.items,
          page: paged.meta.currentPage,
          totalPages: paged.meta.totalPages,
          loadingMore: false,
        ),
      ),
    );
  }
}
