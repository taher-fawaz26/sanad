import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_ui/src/pagination/paging_state_adapter.dart';

void main() {
  group('toPagingState', () {
    test(
      'initial (never fetched) reports loading, not an empty result',
      () {
        // Regression: a freshly-constructed PaginationData (before the BLoC
        // dispatches its first fetch) must not look "loaded and empty" —
        // that rendered infinite_scroll_pagination's no-items-found
        // indicator for a frame (the manager-picker premature "No Results"
        // bug).
        const data = PaginationData<int>();
        expect(data.status, RequestStatus.initial);

        final paging = toPagingState(data);

        expect(paging.isLoading, isTrue);
        expect(paging.pages, isEmpty);
        expect(paging.error, isNull);
      },
    );

    test('first-page loading reports loading with no pages', () {
      const data = PaginationData<int>(status: RequestStatus.loading);
      final paging = toPagingState(data);

      expect(paging.isLoading, isTrue);
      expect(paging.pages, isEmpty);
    });

    test('success with items exposes one logical page, not loading', () {
      const data = PaginationData<int>(
        status: RequestStatus.success,
        items: [1, 2, 3],
        meta: PageMeta(
          totalItems: 3,
          itemCount: 3,
          itemsPerPage: 20,
          totalPages: 1,
          currentPage: 1,
        ),
      );
      final paging = toPagingState(data);

      expect(paging.isLoading, isFalse);
      expect(paging.pages, [
        [1, 2, 3],
      ]);
      expect(paging.hasNextPage, isFalse);
    });

    test(
      'genuine empty (success + no items) is idle so the empty state shows',
      () {
        const data = PaginationData<int>(
          status: RequestStatus.success,
        );
        final paging = toPagingState(data);

        expect(paging.isLoading, isFalse);
        expect(paging.pages, isEmpty);
        expect(paging.error, isNull);
      },
    );

    test('loading more keeps existing items and reports loading', () {
      const data = PaginationData<int>(
        status: RequestStatus.success,
        items: [1, 2],
        loadingMore: true,
        meta: PageMeta(
          totalItems: 4,
          itemCount: 2,
          itemsPerPage: 2,
          totalPages: 2,
          currentPage: 1,
        ),
      );
      final paging = toPagingState(data);

      expect(paging.isLoading, isTrue);
      expect(paging.pages, [
        [1, 2],
      ]);
      expect(paging.hasNextPage, isTrue);
    });

    test('first-page failure surfaces the error', () {
      const data = PaginationData<int>(
        status: RequestStatus.failure,
        firstPageError: UnknownFailure(message: 'boom'),
      );
      final paging = toPagingState(data);

      expect(paging.error, isA<UnknownFailure>());
      expect(paging.isLoading, isFalse);
    });
  });
}
