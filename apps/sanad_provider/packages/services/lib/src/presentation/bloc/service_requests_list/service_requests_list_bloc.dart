import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/domain/usecases/get_my_service_requests_usecase.dart';

part 'service_requests_list_event.dart';
part 'service_requests_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Query for [GetMyServiceRequestsUseCase], adapted to [PageQuery] so
/// [ServiceRequestsListBloc] can use the shared [PaginationMixin] instead of
/// hand-rolling fetch/append/error reducers.
class _ServiceRequestsQuery extends PageQuery {
  const _ServiceRequestsQuery({
    super.page,
    super.limit = 10,
    super.search,
    this.status,
  });

  final ServiceRequestStatus? status;

  @override
  _ServiceRequestsQuery copyWithPage(int page) => _ServiceRequestsQuery(
    page: page,
    limit: limit,
    search: search,
    status: status,
  );

  @override
  List<Object?> get props => [...super.props, status];
}

/// Owns the "Service request" tab: the provider's own submitted requests
/// (`GET /service-requests`), including server-side search and status
/// filter (underreview/approved/rejected/all).
class ServiceRequestsListBloc
    extends Bloc<ServiceRequestsListEvent, ServiceRequestsListState>
    with
        PaginationMixin<
          ServiceRequestsListEvent,
          ServiceRequestsListState,
          ServiceRequestEntity,
          _ServiceRequestsQuery
        > {
  ServiceRequestsListBloc({
    required GetMyServiceRequestsUseCase getMyServiceRequestsUseCase,
  }) : _getMyServiceRequestsUseCase = getMyServiceRequestsUseCase,
       super(const ServiceRequestsListState()) {
    on<ServiceRequestsListFetchEvent>(
      (event, emit) => loadFirstPage(emit),
      transformer: droppable(),
    );
    on<ServiceRequestsListRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<ServiceRequestsListLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<ServiceRequestsListSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<ServiceRequestsListStatusChangedEvent>(
      _onStatusChanged,
      transformer: restartable(),
    );
  }

  final GetMyServiceRequestsUseCase _getMyServiceRequestsUseCase;

  Future<void> _onSearchChanged(
    ServiceRequestsListSearchChangedEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  Future<void> _onStatusChanged(
    ServiceRequestsListStatusChangedEvent event,
    Emitter<ServiceRequestsListState> emit,
  ) async {
    emit(state.copyWith(statusFilter: event.status));
    await onQueryChanged(emit);
  }

  @override
  PaginationData<ServiceRequestEntity> readPage(
    ServiceRequestsListState state,
  ) => state.pagination;

  @override
  ServiceRequestsListState writePage(
    ServiceRequestsListState state,
    PaginationData<ServiceRequestEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  _ServiceRequestsQuery buildQuery({required int page}) =>
      _ServiceRequestsQuery(
        page: page,
        search: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
        status: state.statusFilter == ServiceRequestStatus.all
            ? null
            : state.statusFilter,
      );

  @override
  TaskEither<Failure, Page<ServiceRequestEntity>> fetchPage(
    _ServiceRequestsQuery query,
  ) =>
      _getMyServiceRequestsUseCase(
        GetMyServiceRequestsParams(
          page: query.page,
          limit: query.limit,
          search: query.search,
          status: query.status,
        ),
      ).map(
        (result) => Page(
          items: result.items,
          meta: PageMeta(
            totalItems: result.meta.totalItems,
            itemCount: result.meta.itemCount,
            itemsPerPage: result.meta.itemsPerPage,
            totalPages: result.meta.totalPages,
            currentPage: result.meta.currentPage,
          ),
        ),
      );

  @override
  Object dedupKey(ServiceRequestEntity item) => item.id;
}
