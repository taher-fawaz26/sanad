import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';

part 'client_requests_list_event.dart';
part 'client_requests_list_state.dart';

/// The client's own requests, split into the screen's three tabs.
///
/// ## Where the filtering happens
///
/// Two of the three tabs narrow **server-side** (`GET /requests?status=`),
/// which is the only way a paginated list can filter correctly: filtering a
/// loaded page would show an arbitrary subset of the matches and an incorrect
/// "no more" state.
///
/// [ClientRequestsTab.active] cannot, because it spans five statuses and the
/// endpoint takes one. It therefore reads unfiltered and drops the two
/// statuses the *other* tabs own — a client-side step, taken deliberately and
/// kept as small as possible. The cost is bounded and visible: a page whose
/// rows are mostly scheduled or cancelled renders short, and the user pulls
/// for more. The alternative — sending a repeated `status` parameter the
/// backend has not been observed to accept — risks a 400 or, worse, a
/// silently unfiltered list.
///
/// ## Ordering
///
/// Rows that need the client are hoisted to the front, stably, so the screen's
/// two sections ("Needs your attention", then the tab's own heading) are a
/// straight walk down one list. That is a *presentation order* over the same
/// items, not a filter: nothing is hidden and page order is otherwise
/// preserved.
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
  ClientRequestsListBloc({
    required ListClientRequestsUseCase listRequests,
    required CancelClientRequestUseCase cancelRequest,
  }) : _listRequests = listRequests,
       _cancelRequest = cancelRequest,
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
    on<ClientRequestsTabChanged>(_onTabChanged, transformer: restartable());
    // Droppable: a double-tapped Cancel must not send two cancellations.
    on<ClientRequestCancelRequested>(_onCancel, transformer: droppable());
    on<ClientRequestsMutationAcknowledged>(
      (_, emit) => emit(state.copyWith(clearMutation: true)),
    );
  }

  final ListClientRequestsUseCase _listRequests;
  final CancelClientRequestUseCase _cancelRequest;

  @override
  PaginationData<ClientRequest> readPage(ClientRequestsListState state) =>
      state.data;

  @override
  ClientRequestsListState writePage(
    ClientRequestsListState state,
    PaginationData<ClientRequest> data,
  ) => state.copyWith(data: data.copyWith(items: _arrange(data.items)));

  @override
  ClientRequestsQuery buildQuery({required int page}) =>
      ClientRequestsQuery(page: page, status: state.tab.serverStatus);

  @override
  Object? dedupKey(ClientRequest item) => item.id;

  @override
  TaskEither<Failure, Page<ClientRequest>> fetchPage(
    ClientRequestsQuery query,
  ) => _listRequests(query);

  /// Drops what this tab does not own, then hoists the rows waiting on the
  /// client. Both steps are stable, so a refresh never reshuffles equals.
  List<ClientRequest> _arrange(List<ClientRequest> items) {
    final admitted = items
        .where((request) => state.tab.admits(request.status))
        .toList();
    return [
      ...admitted.where((request) => request.needsAttention),
      ...admitted.where((request) => !request.needsAttention),
    ];
  }

  Future<void> _onTabChanged(
    ClientRequestsTabChanged event,
    Emitter<ClientRequestsListState> emit,
  ) async {
    if (event.tab == state.tab) return;
    emit(state.copyWith(tab: event.tab));
    await onQueryChanged(emit);
  }

  Future<void> _onCancel(
    ClientRequestCancelRequested event,
    Emitter<ClientRequestsListState> emit,
  ) async {
    emit(state.copyWith(mutation: RequestStatus.loading));

    final result = await _cancelRequest(
      ReasonedRequestParams(id: event.id, reason: event.reason),
    ).run();

    result.match(
      (failure) => emit(
        state.copyWith(mutation: RequestStatus.failure, failure: failure),
      ),
      (cancelled) {
        // The server's own post-action request replaces the row — never a
        // locally-assumed CANCELLED, which a concurrent server transition
        // could already have overtaken. Re-arranging then drops it from
        // Active, because a cancelled request belongs to the Cancelled tab;
        // that is the same rule the list already applies to a fetched page,
        // not a special case for this action.
        final replaced = [
          for (final request in state.data.items)
            if (request.id == cancelled.id) cancelled else request,
        ];
        emit(
          state.copyWith(
            data: state.data.copyWith(items: _arrange(replaced)),
            mutation: RequestStatus.success,
          ),
        );
      },
    );
  }
}
