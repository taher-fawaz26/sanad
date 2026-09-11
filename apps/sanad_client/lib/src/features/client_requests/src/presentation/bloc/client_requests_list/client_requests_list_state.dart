part of 'client_requests_list_bloc.dart';

/// The requests list, the visible tab, and the state of an inline mutation.
class ClientRequestsListState extends Equatable {
  /// Creates the list state.
  const ClientRequestsListState({
    this.data = const PaginationData<ClientRequest>(),
    this.tab = ClientRequestsTab.active,
    this.mutation = RequestStatus.initial,
    this.failure,
  });

  /// The paginated rows, plus their load and error state.
  ///
  /// Already arranged for the visible tab: rows the other tabs own are gone,
  /// and the ones waiting on the client come first. See
  /// [ClientRequestsListBloc].
  final PaginationData<ClientRequest> data;

  /// The visible segment. Figma opens on Active (`8385:4379`).
  final ClientRequestsTab tab;

  /// Lifecycle of an inline card action — today, Cancel.
  final RequestStatus mutation;

  /// Why the last mutation failed, if it did.
  final Failure? failure;

  /// The rows the client has to do something about, in order.
  Iterable<ClientRequest> get needingAttention =>
      data.items.where((request) => request.needsAttention);

  /// Everything else, in order.
  Iterable<ClientRequest> get remaining =>
      data.items.where((request) => !request.needsAttention);

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass `clearMutation` to return to [RequestStatus.initial] and drop the
  /// failure; a plain `??` merge can only ever set one.
  ClientRequestsListState copyWith({
    PaginationData<ClientRequest>? data,
    ClientRequestsTab? tab,
    RequestStatus? mutation,
    Failure? failure,
    bool clearMutation = false,
  }) => ClientRequestsListState(
    data: data ?? this.data,
    tab: tab ?? this.tab,
    mutation: clearMutation
        ? RequestStatus.initial
        : (mutation ?? this.mutation),
    failure: clearMutation ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [data, tab, mutation, failure];
}
