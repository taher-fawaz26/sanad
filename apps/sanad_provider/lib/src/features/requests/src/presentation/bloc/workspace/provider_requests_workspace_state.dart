part of 'provider_requests_workspace_bloc.dart';

/// The workspace feed, its filters, and the server-computed summary numbers.
class ProviderRequestsWorkspaceState extends Equatable {
  /// Creates the workspace state.
  const ProviderRequestsWorkspaceState({
    this.data = const PaginationData<ProviderRequest>(),
    this.counts = ProviderRequestCounts.empty,
    this.stats = const ProviderRequestStats(),
    this.tab,
    this.search,
    this.branchId,
  });

  /// The paginated rows, plus their load and error state.
  final PaginationData<ProviderRequest> data;

  /// Badge counts per tab, from the server.
  final ProviderRequestCounts counts;

  /// The four headline numbers, from the server.
  final ProviderRequestStats stats;

  /// The active tab. `null` shows every tab.
  final ProviderRequestTab? tab;

  /// The active search term.
  final String? search;

  /// The active branch filter.
  final String? branchId;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear*` flags exist because each of these filters can legitimately
  /// be set back to `null`, which a plain `??` merge can never express.
  ProviderRequestsWorkspaceState copyWith({
    PaginationData<ProviderRequest>? data,
    ProviderRequestCounts? counts,
    ProviderRequestStats? stats,
    ProviderRequestTab? tab,
    bool clearTab = false,
    String? search,
    bool clearSearch = false,
    String? branchId,
    bool clearBranchId = false,
  }) => ProviderRequestsWorkspaceState(
    data: data ?? this.data,
    counts: counts ?? this.counts,
    stats: stats ?? this.stats,
    tab: clearTab ? tab : (tab ?? this.tab),
    search: clearSearch ? search : (search ?? this.search),
    branchId: clearBranchId ? branchId : (branchId ?? this.branchId),
  );

  @override
  List<Object?> get props => [data, counts, stats, tab, search, branchId];
}
