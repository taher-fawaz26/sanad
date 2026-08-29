import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/usecases/list_provider_services_usecase.dart';

part 'services_list_event.dart';
part 'services_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Query for [ListProviderServicesUseCase], adapted to [PageQuery] so
/// [ServicesListBloc] can use the shared [PaginationMixin] instead of
/// hand-rolling fetch/append/error reducers.
class _ServicesQuery extends PageQuery {
  const _ServicesQuery({
    super.page,
    super.limit = 10,
    super.search,
    this.status,
  });

  final ProviderServiceStatus? status;

  @override
  _ServicesQuery copyWithPage(int page) => _ServicesQuery(
    page: page,
    limit: limit,
    search: search,
    status: status,
  );

  @override
  List<Object?> get props => [...super.props, status];
}

/// Owns the provider's own services list on the dashboard (`GET
/// /provider-services`): fetch, refresh, load-more, search, status filter,
/// and a client-side category filter derived from the loaded services
/// themselves (see [ServicesListCategoryChangedEvent]).
///
/// Does not own single-service mutations (delete / status toggle) — those
/// live in [ServiceActionBloc]; success is folded back in here via
/// [ServiceReplacedInListEvent] / [ServiceRemovedFromListEvent].
class ServicesListBloc extends Bloc<ServicesListEvent, ServicesListState>
    with
        PaginationMixin<
          ServicesListEvent,
          ServicesListState,
          ProviderServiceEntity,
          _ServicesQuery
        > {
  ServicesListBloc({
    required ListProviderServicesUseCase listProviderServicesUseCase,
  }) : _listProviderServicesUseCase = listProviderServicesUseCase,
       super(const ServicesListState()) {
    on<ServicesListFetchEvent>(
      (event, emit) => loadFirstPage(emit),
      transformer: droppable(),
    );
    on<ServicesListRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<ServicesListLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<ServicesListSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<ServicesListStatusChangedEvent>(
      _onStatusChanged,
      transformer: restartable(),
    );
    on<ServicesListCategoryChangedEvent>(_onCategoryChanged);
    on<ServiceReplacedInListEvent>(_onReplaced);
    on<ServiceRemovedFromListEvent>(_onRemoved);
  }

  final ListProviderServicesUseCase _listProviderServicesUseCase;

  Future<void> _onSearchChanged(
    ServicesListSearchChangedEvent event,
    Emitter<ServicesListState> emit,
  ) async {
    // Atomic transition: update the query AND flip pagination to loading in
    // ONE emit, so no downstream selector ever observes the pair
    // `(items: <old, stale>, searchQuery: <new>)`. The UI's onboarding
    // "no services added yet" predicate — status:success + items:[] +
    // searchQuery:'' + no filters — was previously satisfied for one frame
    // when the user cleared a no-results query (SAN-580 follow-up): the
    // old items were still `[]` from the failed search, the new
    // `searchQuery` was already `''`, and `status` had not yet been reset
    // to loading (that happens 350ms later inside `onQueryChanged`).
    // Emitting the reset up-front closes that window without any UI-side
    // guards or delays.
    emit(
      state.copyWith(
        searchQuery: event.query,
        pagination: const PaginationData<ProviderServiceEntity>(
          status: RequestStatus.loading,
        ),
      ),
    );
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  Future<void> _onStatusChanged(
    ServicesListStatusChangedEvent event,
    Emitter<ServicesListState> emit,
  ) async {
    // Same atomic transition as `_onSearchChanged`: reset pagination to
    // loading in the SAME emit that updates the filter, so a
    // status/category change never briefly renders a partly-updated state.
    emit(
      state.copyWith(
        statusFilter: event.status,
        pagination: const PaginationData<ProviderServiceEntity>(
          status: RequestStatus.loading,
        ),
      ),
    );
    await onQueryChanged(emit);
  }

  /// Purely client-side: re-filters the already-loaded [state.services] by
  /// `category.id`, no server round trip (`GET /provider-services` has no
  /// `categoryId` query param).
  void _onCategoryChanged(
    ServicesListCategoryChangedEvent event,
    Emitter<ServicesListState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearSelectedCategory: event.categoryId == null,
      ),
    );
  }

  void _onReplaced(
    ServiceReplacedInListEvent event,
    Emitter<ServicesListState> emit,
  ) {
    final updated = state.services
        .map((s) => s.id == event.service.id ? event.service : s)
        .toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  void _onRemoved(
    ServiceRemovedFromListEvent event,
    Emitter<ServicesListState> emit,
  ) {
    final updated = state.services
        .where((s) => s.id != event.serviceId)
        .toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  @override
  PaginationData<ProviderServiceEntity> readPage(ServicesListState state) =>
      state.pagination;

  @override
  ServicesListState writePage(
    ServicesListState state,
    PaginationData<ProviderServiceEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  _ServicesQuery buildQuery({required int page}) => _ServicesQuery(
    page: page,
    search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
    status: state.statusFilter == ProviderServiceStatus.all
        ? null
        : state.statusFilter,
  );

  @override
  TaskEither<Failure, Page<ProviderServiceEntity>> fetchPage(
    _ServicesQuery query,
  ) =>
      _listProviderServicesUseCase(
        ListProviderServicesParams(
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
  Object dedupKey(ProviderServiceEntity item) => item.id;
}
