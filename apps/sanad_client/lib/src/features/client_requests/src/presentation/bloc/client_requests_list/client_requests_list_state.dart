part of 'client_requests_list_bloc.dart';

/// The requests list, plus the active server-side status filter.
class ClientRequestsListState extends Equatable {
  /// Creates the list state.
  const ClientRequestsListState({
    this.data = const PaginationData<ClientRequest>(),
    this.statusFilter,
  });

  /// The paginated rows, plus their load and error state.
  final PaginationData<ClientRequest> data;

  /// The active server-side filter. `null` means all statuses.
  final ClientRequestStatus? statusFilter;

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass `clearStatusFilter` to actually set the filter to
  /// `null`; a plain `??` merge can only ever add one.
  ClientRequestsListState copyWith({
    PaginationData<ClientRequest>? data,
    ClientRequestStatus? statusFilter,
    bool clearStatusFilter = false,
  }) => ClientRequestsListState(
    data: data ?? this.data,
    statusFilter: clearStatusFilter
        ? statusFilter
        : (statusFilter ?? this.statusFilter),
  );

  @override
  List<Object?> get props => [data, statusFilter];
}
