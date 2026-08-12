import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('toPagingState', () {
    test('maps an initial (empty, not loading) state', () {
      final state = toPagingState(const PaginationData<int>());
      expect(state.pages, isEmpty);
      expect(state.keys, isEmpty);
      expect(state.hasNextPage, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('maps a first-page loading state', () {
      final state = toPagingState(
        const PaginationData<int>(status: RequestStatus.loading),
      );
      expect(state.isLoading, isTrue);
      expect(state.pages, isEmpty);
    });

    test('maps loaded items as a single accumulated page', () {
      const meta = PageMeta(
        totalItems: 4,
        itemCount: 2,
        itemsPerPage: 2,
        totalPages: 2,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1, 2],
          meta: meta,
        ),
      );
      expect(state.pages, [
        [1, 2],
      ]);
      expect(state.keys, [1]);
      expect(state.hasNextPage, isTrue);
    });

    test('maps hasNextPage=false on the last page', () {
      const meta = PageMeta(
        totalItems: 2,
        itemCount: 2,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1, 2],
          meta: meta,
        ),
      );
      expect(state.hasNextPage, isFalse);
    });

    test('surfaces a first-page error', () {
      const failure = ServerFailure(message: 'boom');
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.failure,
          firstPageError: failure,
        ),
      );
      expect(state.error, failure);
      expect(state.pages, isEmpty);
    });

    test('surfaces a next-page error while keeping existing items', () {
      const failure = ServerFailure(message: 'boom');
      const meta = PageMeta(
        totalItems: 2,
        itemCount: 1,
        itemsPerPage: 1,
        totalPages: 2,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1],
          meta: meta,
          nextPageError: failure,
        ),
      );
      expect(state.error, failure);
      expect(state.pages, [
        [1],
      ]);
    });

    test('isLoading reflects loadingMore during pagination', () {
      const meta = PageMeta(
        totalItems: 2,
        itemCount: 1,
        itemsPerPage: 1,
        totalPages: 2,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1],
          meta: meta,
          loadingMore: true,
        ),
      );
      expect(state.isLoading, isTrue);
    });

    test('returns a PagingState instance', () {
      expect(
        toPagingState(const PaginationData<int>()),
        isA<PagingState<int, int>>(),
      );
    });
  });
}
