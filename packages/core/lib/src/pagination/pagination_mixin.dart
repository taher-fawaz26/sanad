import 'package:bloc/bloc.dart';
import 'package:core/src/blocs/request_status.dart';
import 'package:core/src/domain/failures/failure.dart';
import 'package:core/src/pagination/page.dart';
import 'package:core/src/pagination/page_query.dart';
import 'package:core/src/pagination/pagination_data.dart';
import 'package:fpdart/fpdart.dart';

/// Shared pagination state machine for list BLoCs. Mix this into a feature's
/// `Bloc<Event, State>` to get first-page load, next-page load, refresh, and
/// query-change (search/filter reset) reducers without re-implementing the
/// same fetch/append/error/guard logic per feature.
///
/// The feature owns its `Event`/`State` types and wires its own event
/// handlers (`on<...>`) to the reducers below — this mixin never touches
/// `Bloc.on` itself, so the feature stays free to add its own events
/// (mutation fold-ins, extra filters, ...) alongside pagination.
///
/// Type params: [Item] is the entity type being paginated; [Q] is the
/// feature's query type (its usecase `Params`, extending [PageQuery]).
mixin PaginationMixin<Event, State, Item, Q extends PageQuery>
    on Bloc<Event, State> {
  /// Reads the embedded [PaginationData] slice out of the current state.
  PaginationData<Item> readPage(State state);

  /// Returns a copy of [state] with its [PaginationData] slice replaced.
  State writePage(State state, PaginationData<Item> data);

  /// Builds the query for [page], folding in the current search/filter
  /// fields the feature keeps in its own state.
  Q buildQuery({required int page});

  /// Executes the fetch for [query]. Typically just calls the feature's
  /// usecase.
  TaskEither<Failure, Page<Item>> fetchPage(Q query);

  /// Stable identity used to dedupe appended items across pages (e.g. when
  /// the same record shows up on two consecutive page fetches because the
  /// backing list shifted between requests).
  ///
  /// Defaults to the item itself, which only dedupes correctly for
  /// `Equatable` items whose fields are stable across fetches — not a safe
  /// assumption for every entity shape. Override with a real identity, e.g.
  /// `Object dedupKey(WorkerEntity item) => item.id;`, whenever the entity
  /// has a stable id field.
  Object? dedupKey(Item item) => item;

  /// Bumped by every operation that starts a fresh page-1 view
  /// ([loadFirstPage], [refresh], [onQueryChanged]). A fetch started under
  /// an earlier epoch is dropped when it resolves instead of being applied,
  /// so a slow `loadNextPage` (or a superseded `refresh`) can never land
  /// after a newer one and graft stale rows / stale `meta` onto it —
  /// `loadNextPage` runs under `droppable()` while search/filter changes
  /// typically run under `restartable()`, so they don't cancel each other
  /// via `bloc_concurrency` alone.
  int _fetchEpoch = 0;

  /// Loads page 1, replacing any existing items. Use for initial load and
  /// for retrying after a first-page error.
  Future<void> loadFirstPage(Emitter<State> emit) async {
    final epoch = ++_fetchEpoch;
    final data = readPage(state).copyWith(
      status: RequestStatus.loading,
      loadingMore: false,
      clearFirstPageError: true,
    );
    emit(writePage(state, data));
    await _fetch(emit, page: 1, append: false, epoch: epoch);
  }

  /// Loads the next page and appends it. No-op if already loading more or
  /// there is no next page — callers do not need to guard this themselves.
  Future<void> loadNextPage(Emitter<State> emit) async {
    final data = readPage(state);
    if (data.loadingMore || !data.hasMore) return;
    emit(
      writePage(
        state,
        data.copyWith(loadingMore: true, clearNextPageError: true),
      ),
    );
    await _fetch(emit, page: data.nextPage, append: true, epoch: _fetchEpoch);
  }

  /// Reloads page 1 (pull-to-refresh / manual refresh), replacing items but
  /// preserving the current search/filter query.
  Future<void> refresh(Emitter<State> emit) async {
    final epoch = ++_fetchEpoch;
    final data = readPage(state).copyWith(
      status: RequestStatus.loading,
      loadingMore: false,
      clearFirstPageError: true,
    );
    emit(writePage(state, data));
    await _fetch(emit, page: 1, append: false, epoch: epoch);
  }

  /// Call after the feature updates its search/filter/sort fields. Resets
  /// to page 1 and clears previously loaded items before re-fetching, so a
  /// changed query never mixes results with the old one.
  Future<void> onQueryChanged(Emitter<State> emit) async {
    final epoch = ++_fetchEpoch;
    emit(
      writePage(state, PaginationData<Item>(status: RequestStatus.loading)),
    );
    await _fetch(emit, page: 1, append: false, epoch: epoch);
  }

  Future<void> _fetch(
    Emitter<State> emit, {
    required int page,
    required bool append,
    required int epoch,
  }) async {
    final query = buildQuery(page: page);
    final result = await fetchPage(query).run();
    // A newer loadFirstPage/refresh/onQueryChanged already superseded this
    // fetch — applying it now would graft a stale page (or stale `meta`)
    // onto whatever that newer operation already loaded.
    if (epoch != _fetchEpoch) return;
    result.match(
      (failure) {
        final current = readPage(state);
        final data = append
            ? current.copyWith(loadingMore: false, nextPageError: failure)
            : current.copyWith(
                status: RequestStatus.failure,
                loadingMore: false,
                firstPageError: failure,
              );
        emit(writePage(state, data));
      },
      (fetched) {
        final current = readPage(state);
        final items = append
            ? _mergeDedup(current.items, fetched.items)
            : fetched.items;
        final data = current.copyWith(
          status: RequestStatus.success,
          items: items,
          meta: fetched.meta,
          loadingMore: false,
          clearNextPageError: true,
        );
        emit(writePage(state, data));
      },
    );
  }

  /// Appends [incoming] to [existing], skipping any item whose [dedupKey]
  /// is already present.
  List<Item> _mergeDedup(List<Item> existing, List<Item> incoming) {
    final seen = existing.map(dedupKey).toSet();
    final appended = incoming.where((item) => seen.add(dedupKey(item)));
    return [...existing, ...appended];
  }
}
