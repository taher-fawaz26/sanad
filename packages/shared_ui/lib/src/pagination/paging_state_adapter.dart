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
PagingState<int, T> toPagingState<T>(PaginationData<T> data) {
  return PagingState<int, T>(
    pages: data.items.isEmpty ? const [] : [data.items],
    keys: data.items.isEmpty ? const [] : const [1],
    hasNextPage: data.hasMore,
    isLoading: data.isLoadingFirstPage || data.loadingMore,
    error: data.firstPageError ?? data.nextPageError,
  );
}
