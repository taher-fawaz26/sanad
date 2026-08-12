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

  /// Loads page 1, replacing any existing items. Use for initial load and
  /// for retrying after a first-page error.
  Future<void> loadFirstPage(Emitter<State> emit) async {
    final data = readPage(state).copyWith(
      status: RequestStatus.loading,
      clearFirstPageError: true,
    );
    emit(writePage(state, data));
    await _fetch(emit, page: 1, append: false);
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
    await _fetch(emit, page: data.nextPage, append: true);
  }

  /// Reloads page 1 (pull-to-refresh / manual refresh), replacing items but
  /// preserving the current search/filter query.
  Future<void> refresh(Emitter<State> emit) async {
    final data = readPage(state).copyWith(
      status: RequestStatus.loading,
      clearFirstPageError: true,
    );
    emit(writePage(state, data));
    await _fetch(emit, page: 1, append: false);
  }

  /// Call after the feature updates its search/filter/sort fields. Resets
  /// to page 1 and clears previously loaded items before re-fetching, so a
  /// changed query never mixes results with the old one.
  Future<void> onQueryChanged(Emitter<State> emit) async {
    emit(
      writePage(state, PaginationData<Item>(status: RequestStatus.loading)),
    );
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _fetch(
    Emitter<State> emit, {
    required int page,
    required bool append,
  }) async {
    final query = buildQuery(page: page);
    final result = await fetchPage(query).run();
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

  /// Appends [incoming] to [existing], skipping any item already present.
  /// Relies on entity `Equatable` equality (id + fields) rather than a
  /// caller-supplied id extractor, matching every existing entity in the
  /// codebase.
  List<Item> _mergeDedup(List<Item> existing, List<Item> incoming) {
    final seen = existing.toSet();
    final appended = incoming.where(seen.add);
    return [...existing, ...appended];
  }
}
