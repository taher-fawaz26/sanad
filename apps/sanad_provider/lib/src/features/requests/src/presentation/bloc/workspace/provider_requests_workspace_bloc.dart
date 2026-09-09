import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request_summary.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';
import 'package:sanad_provider/src/features/requests/src/domain/usecases/provider_request_usecases.dart';

part 'provider_requests_workspace_event.dart';
part 'provider_requests_workspace_state.dart';

/// Debounce applied to search keystrokes before they reach the server.
const _searchDebounce = Duration(milliseconds: 350);

/// The provider workspace: a tabbed, searchable feed with badge counts and
/// headline stats.
///
/// **Nothing here derives a tab.** The tab is a server-computed field on each
/// row and a server-side filter on the feed. It depends on this provider's own
/// offer thread as well as the request status, so the device cannot reproduce
/// it — and a paginated feed cannot be re-bucketed after the fact without also
/// invalidating the counts.
class ProviderRequestsWorkspaceBloc
    extends Bloc<ProviderRequestsWorkspaceEvent, ProviderRequestsWorkspaceState>
    with
        PaginationMixin<
          ProviderRequestsWorkspaceEvent,
          ProviderRequestsWorkspaceState,
          ProviderRequest,
          ProviderRequestsQuery
        > {
  /// Creates the workspace bloc.
  ProviderRequestsWorkspaceBloc({
    required ListProviderRequestsUseCase listRequests,
    required GetProviderRequestCountsUseCase getCounts,
    required GetProviderRequestStatsUseCase getStats,
  }) : _listRequests = listRequests,
       _getCounts = getCounts,
       _getStats = getStats,
       super(const ProviderRequestsWorkspaceState()) {
    on<ProviderWorkspaceStarted>(_onStarted);
    on<ProviderWorkspaceNextPageRequested>(
      (_, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<ProviderWorkspaceRefreshed>(_onRefreshed, transformer: restartable());
    on<ProviderWorkspaceTabChanged>(_onTabChanged, transformer: restartable());
    // `restartable()` plus an in-handler delay is how this codebase debounces
    // search (see `ServiceRequestsListBloc`): a newer keystroke cancels the
    // pending handler before its fetch starts.
    on<ProviderWorkspaceSearchChanged>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<ProviderWorkspaceBranchFilterChanged>(
      _onBranchChanged,
      transformer: restartable(),
    );
  }

  final ListProviderRequestsUseCase _listRequests;
  final GetProviderRequestCountsUseCase _getCounts;
  final GetProviderRequestStatsUseCase _getStats;

  @override
  PaginationData<ProviderRequest> readPage(
    ProviderRequestsWorkspaceState state,
  ) => state.data;

  @override
  ProviderRequestsWorkspaceState writePage(
    ProviderRequestsWorkspaceState state,
    PaginationData<ProviderRequest> data,
  ) => state.copyWith(data: data);

  @override
  ProviderRequestsQuery buildQuery({required int page}) =>
      ProviderRequestsQuery(
        page: page,
        tab: state.tab,
        search: state.search,
        branchId: state.branchId,
      );

  @override
  Object? dedupKey(ProviderRequest item) => item.id;

  @override
  TaskEither<Failure, Page<ProviderRequest>> fetchPage(
    ProviderRequestsQuery query,
  ) => _listRequests(query);

  Future<void> _onStarted(
    ProviderWorkspaceStarted event,
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    await Future.wait([
      loadFirstPage(emit),
      _loadSummary(emit),
    ]);
  }

  Future<void> _onRefreshed(
    ProviderWorkspaceRefreshed event,
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    // The counts and stats move with the feed — a request that expired on a
    // server timer leaves one tab and enters another — so they are re-read
    // together, never independently.
    await Future.wait([
      refresh(emit),
      _loadSummary(emit),
    ]);
  }

  Future<void> _onTabChanged(
    ProviderWorkspaceTabChanged event,
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    if (event.tab == state.tab) return;
    emit(state.copyWith(tab: event.tab, clearTab: true));
    await onQueryChanged(emit);
  }

  Future<void> _onSearchChanged(
    ProviderWorkspaceSearchChanged event,
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    final trimmed = event.search.trim();
    if (trimmed == (state.search ?? '')) return;
    emit(
      state.copyWith(
        search: trimmed.isEmpty ? null : trimmed,
        clearSearch: true,
      ),
    );
    await Future<void>.delayed(_searchDebounce);
    if (emit.isDone) return;
    await onQueryChanged(emit);
  }

  Future<void> _onBranchChanged(
    ProviderWorkspaceBranchFilterChanged event,
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    if (event.branchId == state.branchId) return;
    emit(state.copyWith(branchId: event.branchId, clearBranchId: true));
    await onQueryChanged(emit);
  }

  /// Reads the badge counts and the headline stats.
  ///
  /// Failures are absorbed: a workspace that cannot show its badges is still
  /// usable, and blocking the feed on a secondary call would not be.
  Future<void> _loadSummary(
    Emitter<ProviderRequestsWorkspaceState> emit,
  ) async {
    final results = await Future.wait([
      _getCounts(const NoParams()).run(),
      _getStats(const NoParams()).run(),
    ]);
    if (emit.isDone) return;

    final counts = results[0].toNullable();
    final stats = results[1].toNullable();
    emit(
      state.copyWith(
        counts: counts is ProviderRequestCounts ? counts : null,
        stats: stats is ProviderRequestStats ? stats : null,
      ),
    );
  }
}
