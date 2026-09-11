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

/// Switches the visible segment — Figma `StatusPills` (`8385:4377`).
final class ClientRequestsTabChanged extends ClientRequestsListEvent {
  /// Creates a tab change.
  const ClientRequestsTabChanged(this.tab);

  /// The segment to show.
  final ClientRequestsTab tab;

  @override
  List<Object?> get props => [tab];
}

/// Cancels one request from the list, with the reason the backend requires.
///
/// The list can do this because the card offers it (Figma `CancelButton`,
/// `8433:38470`); the detail screen keeps its own copy of the action because
/// it is reachable without ever passing through the list.
final class ClientRequestCancelRequested extends ClientRequestsListEvent {
  /// Creates the cancellation.
  const ClientRequestCancelRequested({required this.id, required this.reason});

  /// The request to call off.
  final String id;

  /// Free text, 3–1000 characters. Shown to the provider verbatim.
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}

/// Clears a settled mutation once the UI has shown it.
final class ClientRequestsMutationAcknowledged extends ClientRequestsListEvent {
  /// Creates the acknowledgement.
  const ClientRequestsMutationAcknowledged();
}
