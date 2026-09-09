part of 'provider_requests_workspace_bloc.dart';

/// Base type for everything the workspace bloc reacts to.
sealed class ProviderRequestsWorkspaceEvent extends Equatable {
  /// Const so subclasses can be const.
  const ProviderRequestsWorkspaceEvent();

  @override
  List<Object?> get props => const [];
}

/// First load: the feed plus the counts and stats.
final class ProviderWorkspaceStarted extends ProviderRequestsWorkspaceEvent {
  /// Creates the start event.
  const ProviderWorkspaceStarted();
}

/// Infinite-scroll page append.
final class ProviderWorkspaceNextPageRequested
    extends ProviderRequestsWorkspaceEvent {
  /// Creates the append event.
  const ProviderWorkspaceNextPageRequested();
}

/// Re-reads the feed, the counts and the stats together.
///
/// Dispatched on pull-to-refresh, on app resume, after a mutation, and when a
/// push says a request moved — including the transitions the server makes on a
/// timer rather than in response to a tap.
final class ProviderWorkspaceRefreshed extends ProviderRequestsWorkspaceEvent {
  /// Creates the refresh event.
  const ProviderWorkspaceRefreshed();
}

/// Switches workspace tab. `null` means every tab.
final class ProviderWorkspaceTabChanged extends ProviderRequestsWorkspaceEvent {
  /// Creates a tab change.
  const ProviderWorkspaceTabChanged(this.tab);

  /// The tab to show, or `null` for all.
  final ProviderRequestTab? tab;

  @override
  List<Object?> get props => [tab];
}

/// Updates the search term. Debounced before it reaches the server.
final class ProviderWorkspaceSearchChanged
    extends ProviderRequestsWorkspaceEvent {
  /// Creates a search change.
  const ProviderWorkspaceSearchChanged(this.search);

  /// The raw search box contents.
  final String search;

  @override
  List<Object?> get props => [search];
}

/// Narrows the feed to one branch, or `null` for all branches.
final class ProviderWorkspaceBranchFilterChanged
    extends ProviderRequestsWorkspaceEvent {
  /// Creates a branch filter change.
  const ProviderWorkspaceBranchFilterChanged(this.branchId);

  /// The branch to filter by, or `null` for all.
  final String? branchId;

  @override
  List<Object?> get props => [branchId];
}
