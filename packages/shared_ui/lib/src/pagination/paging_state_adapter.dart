import 'package:core/core.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Projects a generic `PaginationData` (owned by a feature BLoC) onto
/// `infinite_scroll_pagination`'s [PagingState]. Pure function — no
/// controller, no side effects — so the BLoC remains the single source of
/// truth and `infinite_scroll_pagination` never drives its own fetch.
///
/// `data.items` are already accumulated by the BLoC (via `PaginationMixin`),
/// so they are surfaced as a single logical page; `hasNextPage` /
/// `isLoading` / `error` drive the package's built-in indicators.
///
/// [RequestStatus.initial] is reported as `isLoading` (not idle): a
/// not-yet-fetched list is loading its first page from the user's point of
/// view, never "loaded and empty". Reporting it as idle made
/// `infinite_scroll_pagination` render the *no-items-found* indicator for
/// the frame(s) between the BLoC's construction and its first
/// `loadFirstPage` emit — a premature empty state (SAN manager-picker bug).
/// The genuine empty state (`RequestStatus.success` + no items) is
/// unaffected: it still reports `isLoading: false` with no error.
PagingState<int, T> toPagingState<T>(PaginationData<T> data) {
  final isFirstLoad =
      data.status == RequestStatus.initial || data.isLoadingFirstPage;
  return PagingState<int, T>(
    pages: data.items.isEmpty ? const [] : [data.items],
    keys: data.items.isEmpty ? const [] : const [1],
    hasNextPage: data.hasMore,
    isLoading: isFirstLoad || data.loadingMore,
    error: data.firstPageError ?? data.nextPageError,
  );
}
