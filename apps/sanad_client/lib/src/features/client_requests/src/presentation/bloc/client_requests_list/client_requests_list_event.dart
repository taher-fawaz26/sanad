part of 'client_requests_list_bloc.dart';

/// Base type for everything the requests-list bloc reacts to.
sealed class ClientRequestsListEvent extends Equatable {
  /// Const so subclasses can be const.
  const ClientRequestsListEvent();

  @override
  List<Object?> get props => const [];
}

/// First load of the list.
final class ClientRequestsStarted extends ClientRequestsListEvent {
  /// Creates the start event.
  const ClientRequestsStarted();
}

/// Infinite-scroll page append.
final class ClientRequestsNextPageRequested extends ClientRequestsListEvent {
  /// Creates the append event.
  const ClientRequestsNextPageRequested();
}

/// Pull-to-refresh, and the re-read performed when the screen becomes active,
/// after a mutation, or when a push signals a server-side change.
final class ClientRequestsRefreshed extends ClientRequestsListEvent {
  /// Creates the refresh event.
  const ClientRequestsRefreshed();
}

/// Changes the server-side status filter. `null` means "all statuses".
final class ClientRequestsFilterChanged extends ClientRequestsListEvent {
  /// Creates a filter change. `null` clears the filter.
  const ClientRequestsFilterChanged(this.status);

  /// The status to filter by, or `null` for all statuses.
  final ClientRequestStatus? status;

  @override
  List<Object?> get props => [status];
}
