import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';

part 'client_requests_list_event.dart';
part 'client_requests_list_state.dart';

/// The client's own requests, filtered by status.
///
/// The filter is applied **server-side** (`GET /requests?status=`) rather than
/// by filtering a loaded page: with pagination, a client-side filter would show
/// an arbitrary subset of the matches and an incorrect "no more" state.
class ClientRequestsListBloc
    extends Bloc<ClientRequestsListEvent, ClientRequestsListState>
    with
        PaginationMixin<
          ClientRequestsListEvent,
          ClientRequestsListState,
          ClientRequest,
          ClientRequestsQuery
        > {
  /// Creates the list bloc.
  ClientRequestsListBloc({required ListClientRequestsUseCase listRequests})
    : _listRequests = listRequests,
      super(const ClientRequestsListState()) {
    on<ClientRequestsStarted>((_, emit) => loadFirstPage(emit));
    on<ClientRequestsNextPageRequested>(
      (_, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<ClientRequestsRefreshed>(
      (_, emit) => refresh(emit),
      transformer: restartable(),
    );
    on<ClientRequestsFilterChanged>(
      _onFilterChanged,
      transformer: restartable(),
    );
  }

  final ListClientRequestsUseCase _listRequests;

  @override
  PaginationData<ClientRequest> readPage(ClientRequestsListState state) =>
      state.data;

  @override
  ClientRequestsListState writePage(
    ClientRequestsListState state,
    PaginationData<ClientRequest> data,
  ) => state.copyWith(data: data);

  @override
  ClientRequestsQuery buildQuery({required int page}) =>
      ClientRequestsQuery(page: page, status: state.statusFilter);

  @override
  Object? dedupKey(ClientRequest item) => item.id;

  @override
  TaskEither<Failure, Page<ClientRequest>> fetchPage(
    ClientRequestsQuery query,
  ) => _listRequests(query);

  Future<void> _onFilterChanged(
    ClientRequestsFilterChanged event,
    Emitter<ClientRequestsListState> emit,
  ) async {
    if (event.status == state.statusFilter) return;
    // `clearStatusFilter` lets the "all statuses" option actually set null;
    // a plain `??` copyWith could only ever add a filter, never remove one.
    emit(
      state.copyWith(statusFilter: event.status, clearStatusFilter: true),
    );
    await onQueryChanged(emit);
  }
}
